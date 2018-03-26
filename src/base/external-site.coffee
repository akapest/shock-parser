request = require 'request'
#require('request-debug')(request);
Promise = require 'bluebird'
mongoose = require 'mongoose'
tough = require 'tough-cookie'
_ = require 'lodash'
fs = require 'fs'
cheerio = require 'cheerio'
Session = require '../db/session.coffee'
db = require '../db/db.coffee'
logger = require('../logger.coffee')('bot:site')
debug = require('debug')('bot:external-site')
bus = require('../bus.coffee')

{SiteError, ExternalError, UnauthorizedError} = require './errors.coffee'

DEFAULT_EXTERNAL_REQUEST_TIMEOUT = 12000 # ms


class ExternalSite
    constructor: ({url, xhrUrl, @defaultHeaders, @settings, @encoding, @defaultCheckLogged}={})->
        @url = xhrUrl or url # api
        @origin = url # head
        @reset()
        @defaultCheckLogged ?= false
        debug 'Created client for ' + JSON.stringify {@url}

    getFullUrl: (relative) -> @url + relative

    getUsernameFromAd: (ad) -> ad.name

    reset: ->
        host = @url.replace('http://','').replace('https://', '').replace(/\/$/, '')
        @headers = _.extend {},
            Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
            'Accept-Encoding': 'gzip, deflate, sdch'
            'Accept-Language': 'de-DE,de;q=0.8,en-US;q=0.6,en;q=0.4'
            'Cache-Control': 'max-age=0'
            'Connection': 'keep-alive'  
            DNT: 1
            Host: host
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36'
            'Upgrade-Insecure-Requests': 1
        , @defaultHeaders
        @headers.Origin = @origin if @origin
        @headers.Referer = @origin if @origin

        @cookie = request.jar()
        @http = request.defaults
            jar: @cookie
            timeout: DEFAULT_EXTERNAL_REQUEST_TIMEOUT
            gzip: true
            forever: true
            headers:  @headers
            encoding: @encoding

    getCookies: ->
        result = []
        for cookie in @cookie.getCookies @url
            result.push cookie.toString()
        result

    setCookies: (cookies) ->
        for cookie in cookies
            @cookie.setCookie cookie, @url

    isLogged: (response, name) ->
        throw new Error('No account name provided') if not name
        return response.body?.indexOf(name) > 0

    getLastHeaders: ->
        _.extend {}, @headers, @lastHeaders, {Cookie: @cookie.getCookieString(@url)}

    setOptions: (@options) -> #

    # the method automatically checks if the result page is "authorized against" the specified username with help of isLogged method
    getPage: (relativeUrl, options={}) => new Promise (resolve, reject) =>
        if @captcha
            Promise.delay(5000).then => {error: @captcha}

        options = _.extend {}, @options, options
        @lastUrl = @url + relativeUrl

        @before @lastUrl, {options}
        {headers, method, form, json, body, checkLogged, accountName, reload, encoding} = options
        accountName ?= @accountName

        reload ?= 0
        checkLogged ?= @defaultCheckLogged
        httpOptions = {method, headers, encoding}

        @lastHeaders = headers

        if form
            method ?= 'post'
            httpOptions = {method, headers, form}
        else if json
            method ?= 'post'
            httpOptions = {method, headers, json, body}
        else
            method ?= 'get'

        @http @lastUrl, httpOptions, (error, response) =>
            error = @handleExternalErrorIfAny({error, response, relativeUrl, options, accountName})
#                @dump response
            console.log 'RESPONSE', {error, response}
            return resolve {error} if error
            {parseHtml} = options
            parseHtml ?= true
            if options.parseJson
                json = JSON.parse response.body
            else if parseHtml
                $ = cheerio.load(response.body)
                if @checkPageForCaptcha($)
    #                @site.dump response
                    @captcha = {id: Math.random(), url:@lastUrl, headers, isCaptcha:true}
                    bus.$emit('show:captcha', {@captcha, resolveCaptcha: => @captcha = false})
                    return resolve {error:@captcha}
                try
                    if checkLogged and not @isLogged(response, accountName)
                        return resolve error: @externalError('Not authorized', {relativeUrl, response, accountName, form, Error: UnauthorizedError})
                catch e
                    return resolve error: @externalError(e.message, {relativeUrl, response, accountName, form})
            resolve({response, $, json, reject, status: response.statusCode, dump: @dump})

    login: ({login, username, password}, options={}) ->
        @_restoreSession username
        .then (session) =>
            check = if session then @_checkThatLoggedIn(username) else Promise.resolve({logged:false})
            check.then ({logged, error}) =>
                logged ?= not error
                if logged
                    @setAccountName username
                    return {logged}
                logger.debug "Trying to login #{username}"
                @_login {login, username, password}, options
                .then (result) =>
                    @setAccountName username
                    @_saveSession(username, result)
                        .then => return result
#                    .then =>
#                        return @getPage '/', {accountName: username} # check that we actully logged in

    setAccountName: (username) ->
        @accountName = username
        logger.debug 'User logged in ' + username

    # check of the username is already incorporated into Site code
    # and is autmatically checked on every request
    # here we have to pass username to the "getPage" method as we are not logged in yet and have not set the username variable yet (somewhere)
    _checkThatLoggedIn: (username) ->
        logger.debug "Check that #{username} logged with session", @cookie.getCookieString(@url)
        url = if _.last(@url) == '/' then '' else '/'
        @getPage(url, {accountName:username, checkLogged: true})

    _login: (user, {dryRun}={}) ->
        return @_dryLoginResult?() or Promise.resolve()  if dryRun
        data = @loginData(user)
        @getPage(data.url, _.extend data, {accountName: user.username, checkLogged:false})
        .then ({response, error}={}) =>
            logger.info('Auth', response.statusCode)
            apiKey = response.body.apiKey
            return {apiKey, logged:!error, error}

    logout: (username) ->
        throw new Error('No logout url') if not @logoutUrl
        @_restoreSession username
        .then =>
            @getPage @logoutUrl
            .then ({error}) ->
                return logger.error 'Failed to logout', error if error
                logger.debug 'Successfully logged out'
            .finally =>
                @_clearSession(username)

    _saveSession: (username) ->
        cookies = @getCookies()
        console.log 'save cookies', cookies
        @_saveCookies username, cookies

    _restoreSession: (username) ->
        @_getCookies(username)
        .then (model) =>
            logger.debug 'restored cookies', model?.cookies
            @reset()
            @setCookies(model?.cookies or [])
            return true
        .catch ->
            logger.debug  'no cookies for the user yet, ok'
            return false

    _saveCookies: (username, cookies) ->
        db.executeQuery Session.update {site: @url, username}, {site: @url, username, cookies}, {upsert: true}

    _getCookies: (username) ->
        db.execute (done) => Session.findOne {site: @url, username}, done

    _clearSession: (username) ->
        db.execute (done) => Session.remove {site: @url, username}, done

    before: (relativeUrl, options={}) ->
        console.log 'REQUEST', relativeUrl, options

    externalError: (message, {relativeUrl, accountName, response, form, Error, data, inner}={}) ->
        Error ?= ExternalError
        # @dump response, accountName
        return new Error {message, @url, relativeUrl, accountName, response, form, data, inner}

    handleExternalErrorIfAny: ({error, response, relativeUrl, options, accountName, form}={}) ->
        response ?= {}
        status = response?.statusCode
        if not status
            message = "Http request error "
            message += error.code if error.code
            message += error.message if error.message
            status = 'ERR'
            message = "Request timeout: #{DEFAULT_EXTERNAL_REQUEST_TIMEOUT}ms"  if error.code == 'ESOCKETTIMEDOUT' or error.code == 'ETIMEDOUT'
            status = 'T/O' if error.code == 'ESOCKETTIMEDOUT' or error.code == 'ETIMEDOUT'

        if message
            return @externalError message, {relativeUrl, response, accountName, inner: error}

        if (response.statusCode - 400) >= 0
            debug response.headers['set-cookie']
            return @externalError 'External http error: ' + (response.statusMessage or response.statusCode), {relativeUrl, response, accountName, form, data: options}

        return null

    createError: ({method, message, data}={}) ->
        return new SiteError
            method: method
            message: message
            data: data

    unauthorizedError: ({method, data}={}) ->
        new UnauthorizedError
            message: 'Not logged in'
            data: data

    dump: (response, name) ->
        time = new Date().toString().replace(/[\s+\(\)]/g, '_')
        name ?= @lastUrl.replace(/[\/]/g, '_')
        file = "./#{response?.statusCode}_#{name}_#{time}.html"
        body = response?.body or 'No response'
        fs.writeFileSync(file, body)

    checkPageForCaptcha: ($) ->
        error = $('.g-recaptcha').length > 0
        message = 'ERROR: access restricted' if error
#        @logger.error message if message
        return message


module.exports = ExternalSite
module.exports.SiteError = SiteError
module.exports.ExternalError = ExternalError
module.exports.UnauthorizedError = UnauthorizedError
