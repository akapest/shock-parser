_ = require  'lodash'
ProxyLists = require 'proxy-lists'
ExternalSite = require './external-site.coffee'
# proxy states: unchecked, busy, active, failed

module.exports =
    init: ->
        return if @inited
        @inited = true
        @all = []
        new Promise (resolve, reject)=>
            gettingProxies = ProxyLists.getProxies {
                countries: null # any 
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

    fetchPage: (url) ->
        proxy = this.next()
        if proxy == null
            console.log('no proxy available')
            return Promise.resolve()
        proxy.state = 'busy'
        proxy.site.getPage url
        .then (result) => 
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
        
    next: () ->
        proxies = _.filter @all, (p) -> p.state != 'failed' and p.state != 'busy'
        if not proxies.length
            return null
        p = proxies[Math.floor(Math.random() * (proxies.length - 1))];
        if !p.site
            p.site = new ExternalSite({
                id: 'SS',
                domain: 'shutterstock.com',
                url: 'https://www.shutterstock.com',
                proxy: p
            })
        console.log 'Next proxy', p
        return p
