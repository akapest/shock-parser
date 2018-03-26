debug = require 'debug'
Rollbar = require 'rollbar'
{prepend} = require './util.coffee'
config = require './config.coffee'
moment = require 'moment'
log = debug('bot:logger')
_ = require 'lodash'
log 'Logger started'
log config

rollbar = new Rollbar
    accessToken: "d75f298dd644415ca47fa1bf2abafb64"
    verbose: true
    enabled: false
    level: 'debug'
    environment: if config.isDev then 'development' else "production"
    codeVersion: config.revision
    version: config.version
    hostname: require('os').hostname()
    scrubHeaders: []
    scrubFields: []

setupErrorHandlers = ->
    logger = createLogger('bot:common')
    process.on 'uncaughtException', (err) -> logger.error('Uncaught error: ' + err.message, err, {stack:err.stack})
    process.on 'unhandledRejection', (err) -> logger.error('Unhandled rejection: ' + err.message, err, {stack:err.stack})

ignoredErrors = [
]

createLogger = (namespace) ->
    throw new Error('Logger namespace should start with "bot:" value: ' + namespace) if namespace?.indexOf('bot:') != 0
    devDebug = debug namespace
    logger = {}

    for level in ['debug', 'info', 'warn', 'error', 'critical']
        createMethod = (level) ->
            return (args...) =>
                devDebug.apply devDebug, args
        logger[level] = createMethod level

    errorHandler = (level) ->
        (message, error={}, data={}) ->
            if not _.isString message
                error = message
                message = null
            else
                error.message = prepend(error.message, message)

            longMessage = prepend(error.message, error.action)
            devDebug longMessage # log to console during dev
            devDebug error.stack # log to console during dev

            data = _.extend error, data

            if ignoredErrors.indexOf(error.message) == -1 and not error.ignoreRollbar
                logger.rollbarMessage error.message, level, data
            else
                console.log 'IGNORE ERROR'

    logger.error = errorHandler('error')
    logger.critical = errorHandler('critical')

    logger.rollbarMessage = (message, level='info', data={}) ->
        return
        {botUsername='NO_NAME', error={}, request={}} = data

        request.user = user = {id: botUsername, username:botUsername}
        request.url ?= data.url or error.url or 'NO_URL'
        request.headers ?= data.headers or error.headers
        request.method ?= data.action or error.action

        delete data.error
        delete data.headers
        delete data.url
        delete data.body
        delete data.method
        delete data.protocol
        delete data.route
        #        delete data.stack

        toString = -> JSON.stringify({message, data, request, user})

        new Promise (resolve, reject) =>
            rollbar[level] message, request, data, error, (err) ->
                if err
                    console.log err
                    console.log "Call to Rollbar failed: " + toString()
                    resolve({
                        success: false})
                else
                    console.log "Successful call to Rollbar " + toString()
                    resolve({success: true})
    return logger

setupErrorHandlers()

module.exports = createLogger
