_ = require  'lodash'
ProxyLists = require 'proxy-lists'
ExternalSite = require './external-site.coffee'
# proxy states: unchecked(null), "active", "failed"
EventEmitter = require('events').EventEmitter || require('events');
getProtocols = (text) ->
    return text.toLowerCase().split(', ')
emitter = new EventEmitter()
headers = {cookie:'__cfduid=dcb2e50c2601c81a633b8a6166e1181851522692251; cf_clearance=74e6bdb84cff620688a81777c997aba458ca7279-1522692256-86400; _ym_uid=1522692256123744806; _ym_isad=1; _ga=GA1.2.13144702.1522692257; _gid=GA1.2.549502026.1522692257; _ym_visorc_42065329=w; jv_enter_ts_PeHzjrJoSL=1522692259856; jv_visits_count_PeHzjrJoSL=1; jv_refer_PeHzjrJoSL=https%3A%2F%2Fhidemy.name%2Fru%2Fproxy-list%2F; jv_utm_PeHzjrJoSL=; PAPVisitorId=45a289001a4c12081d18d5d4d499ce*0; jv_invitation_time_PeHzjrJoSL=1522692384041; jv_pages_count_PeHzjrJoSL=5'}
hmn = new ExternalSite({
    id: 'HMN',
    domain: 'hidemy.name',
    url: 'https://hidemy.name',
    encoding: 'latin1'
})
getProxyPage = (n) ->
    url = "/en/proxy-list/?maxtime=1500&type=hs&start=#{64*n}#list" if n > 1
    url ?= '/en/proxy-list/?maxtime=1500&type=hs#list;'
    hmn.getPage(url, {headers})
    .then ({$, error}) ->
        console.error error if error
        $trs = $('.proxy__t tr')
        list = $trs.map (i, el) ->
            return null if i == 0
            $tds = $(el).find('td')
            return {
                ipAddress: $tds.eq(0).text(),
                port: parseInt($tds.eq(1).text()),
                country: $tds.eq(2).text().trim().substring(0,2).toLowerCase()
                protocols: getProtocols($tds.eq(4).text()),
                source: 'hidemy.name'
                ipTypes:  ['ipv4']
            }
        .toArray()
        console.log "FOUND #{list.length} proxies"
        emitter.emit('data', _.compact(list))

getProxies = ->
    Promise.all([
        getProxyPage 0
        getProxyPage 1
        getProxyPage 2
        getProxyPage 3
    ]).then ->
        emitter.emit('end');
    return emitter

ProxyLists.addSource('hidemy.name', { homeUrl: 'https://hidemy.name', getProxies})

module.exports =
    init: ({sitesPerProxy, pagesPerProxy}={}) ->
        return Promise.resolve() if @inited
        @inited = true
        @all = []
        @maxSitesPerProxy = sitesPerProxy ? 3
        @maxPagesPerSite = pagesPerProxy ? 20
        new Promise (resolve, reject)=>
            gettingProxies = ProxyLists.getProxies {
                countries: null # any
                filterMode: 'loose',
            }
            gettingProxies.on 'data', (proxies) =>
                @all = @all.concat this.filterProxies proxies
                console.log 'Proxies count: ' + @all.length
            
            gettingProxies.on 'error', (error) =>  console.log error # one of sources failed
                
            gettingProxies.once 'end',  =>
                console.log 'Proxies count: ' + @all.length
                if @all.length
                    resolve true
                else
                    reject new Error('Failed to find any proxy')
    inspect: ->
        return {active: @filter('active'), failed: @filter('failed')}

    filter: (state) ->
        _.filter @all, (p) -> p.state == state

    fetchPage: (url) ->
        {proxy, site} = this.next()
        if proxy == null
            console.log('no proxy available')
            return Promise.delay(10*1000).then => @fetchPage(url)
        start = moment()
        site.busy = true
        site.getPage url
        .then (result) =>
            time = moment().diff(start, 'seconds')
            site.busy = false
            site.results.push {time, result}
            if site.results.length >= @maxPagesPerSite
                console.log 'Site GONE', site.results
                _.remove(proxy.sites, (s) -> s == site)
            proxy.lastResult = result
            if !result.error
                proxy.state = 'active'
                return result
            else
                m = result.error?.inner or result.error
                console.log m, proxy, result
                proxy.state = 'failed'
                return this.fetchPage(url)
                    
    filterProxies: (p) -> p

    getProxy: (state) ->
        proxies = _.filter @all, (p) =>
            p.sites ?= []
            p.state == state and (p.sites.length < @maxSitesPerProxy or _.find(p.sites, (site) -> !site.busy))
        p = proxies[Math.floor(Math.random() * (proxies.length - 1))]
        return {} if not p
        site = @initSite(p)
        return {p, site} if site
        return {}

    initSite: (proxy) ->
        proxy.sites ?= []
        site = _.find(proxy.sites, (site) -> !site.busy)
        return site if site and site.results.length < @maxPagesPerSite
        if site or proxy.sites.length < @maxSitesPerProxy
            site = new ExternalSite({
                id: 'SS',
                domain: 'shutterstock.com',
                url: 'https://www.shutterstock.com',
                proxy: proxy
            })
            site.busy = false
            site.results = []
            proxy.sites.push(site)
            return site
        return null

    next: () ->
        {p, site} = @getProxy('active')
        if not p
            {p, site} = @getProxy(undefined)
            if not p
                {p, site} = @getProxy('failed')
        console.log 'Next proxy', p, @inspect()
        return {proxy:p, site}
