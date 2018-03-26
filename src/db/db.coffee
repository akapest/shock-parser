mongoose = require 'mongoose'
Promise = require 'bluebird'
_ = require 'lodash'
debug = require('debug')('bot:db')
mongoose.Promise = Promise

URI = null

init = (uri) ->
    if uri.indexOf('mongodb') != 0
        uri = 'mongodb://localhost/' + uri
    URI = uri
    console.log URI
    debug 'MONGODB_URI', URI

mongoose.set('debug', true)
#mongoose.set('debug', (collectionName, methodName, arg1, arg2...) -> {});

init 'mongodb://localhost/shock-parser'  # admin pass - a8iYpDYcKtpP84

DB_TIMEOUT = 4000

connected = false
connecting = false
connectError = null
statusCode = null

baseConnect = ->
    return if connected or connecting

    connecting = true
    mongoose.connect URI, {autoReconnect:false}

    console.log 'CONNECT', URI

    mongoose.connection.removeAllListeners('disconnected')
    mongoose.connection.removeAllListeners('error')

    mongoose.connection.once 'connected', -> # only once
        debug 'Connection established'
        connected = true
        connecting = false

    mongoose.connection.on 'error', (error) ->
        debug error
        connectError = 'Database is offline, error: ' + error
        disconnect()

    mongoose.connection.once 'disconnected', ->
        debug 'Mongo disconnected'
        disconnect()

    setTimeout ->
        if connecting and not connected
            connecting = false
    , DB_TIMEOUT - 100

connect = ->
    new Promise (resolve, reject) ->
        baseConnect()
        return resolve() if connected
        mongoose.connection.once 'connected', ->
            resolve()
        setTimeout ->
            return resolve() if connected
            debug "Mongo connection timeout (#{DB_TIMEOUT/1000}s)"
            reject 'Database offline. Please contact administrator'
        , DB_TIMEOUT

disconnect = ->
    connected = false
    mongoose.connection.removeAllListeners('connected')
    mongoose.connection.removeAllListeners('error')
    mongoose.connection.removeAllListeners('disconnected')
    mongoose.disconnect()

_success = (isSuccess) ->
    isSuccess ?= true
    return success:true if isSuccess
    return {success:false, message:connectError, code: statusCode}

checkStatus = () -> new Promise (resolve, reject) ->
    connect()
    .then ->
        mongoose.connection.db.admin().ping (error, resp) =>
            if error
                debug 'Ping mongo error', error
                resolve _success(false)
            else
                resolve _success()
    .catch ->
        resolve _success(false)

doneCallback = (getOp, resolve, reject) ->
    (error, result) ->
        {opString, query} = getOp()
        if error
            debug 'DB error: ' + opString, error if error
            return reject error
        else
            if result?.length
                string = 'Length: ' + result.length + ', first: '
                item = result[0]
            else
                string = ''
                item = result
            details = if query.op == 'update' then query._compiledUpdate else ''
#            console.log query.op, query if query.op != 'update'
#            console.log 'DB result: ' + opString, details, string, item?.result or item?
            resolve result

execute = (promiseBody) ->
    connect()
    .then -> new Promise (resolve, reject) ->
        try
            opString = ''
            query = {}
            getOp = -> return {opString, query}
            promiseBody doneCallback(getOp, resolve, reject)
#            console.log 'DB', {entity, query, operation: operation?.op, asString: opString}
        catch e
            console.error e

getInfo = (query) ->
    entity = query._collection?.collectionName
    opString = entity + '.' + query.op + '(' + JSON.stringify(query._conditions) + ', ' + JSON.stringify(query.options) + ')'
    return {entity, query, opString}

executeQuery = (query) ->
    throw new Error("Not a query", query) if not query.exec
    connect()
    .then -> new Promise (resolve, reject) ->
        {entity, opString, query} = getInfo(query)
        getOp = -> return {opString, query}
        query.exec(doneCallback(getOp, resolve, reject))
#        console.log 'DB', {entity, operation: query.op, asString: opString}
    .catch (e) =>
        console.error e
        throw e

#    hasItemInDb: (item) ->
#        throw new Error('shouldFetchNextPage: not enough parameters') if not item
#        @getOneFromDb({id: item.id})
#        .then (item) ->
#            return !!item
#
#    getOneFromDb: (query, projection) ->
#        @getFromDb(query, projection)
#        .then (result) -> return result[0] if result.length
#
#    getFromDb: (query, projection) ->
#        db.getItems(@Item, query, projection)

module.exports =
    init: init
    execute: execute
    executeQuery: executeQuery
    disconnect: disconnect
    checkStatus: checkStatus
    connect: connect
