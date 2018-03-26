_ = require 'lodash'
config = require '../config.coffee'
MAX_BODY_LENGTH = 20*1024 # bytes Max rollbar item length is 128Kb. "Max paylaod size is 128kb."
MAX_BODY_LENGTH = 512 if config.isDev

throw 'MAX_BODY_LENGTH:' + MAX_BODY_LENGTH if MAX_BODY_LENGTH >= 128*1024

class SiteError extends Error
    constructor: ({@message, @data, @code, @accountName, @botUsername, @input, @inputString}={}) ->
        super(arguments)
        @name = "SiteError"
        Error.captureStackTrace(this, SiteError)

class ExternalError extends SiteError
    constructor: ({@url, @relativeUrl, @form, @body, @statusCode, @headers, @inner, response}={}) ->
        super(arguments)
        response ?= {}
        @url = @url + @relativeUrl
        @body ?= response.body or ''
        @statusCode ?= response.statusCode or -1
        @headers ?= response.request?.headers or []

class UnauthorizedError extends ExternalError
    constructor: ->
        super(arguments) # super, not super() to pass along all arguments to parent constructor
        @name = "UnauthorizedError"
        @code = 401

possibleErrorProperties = [
    'message'
    'name'
    'stack'
    'accountName'
    'botUsername'
    'input'
    'inputString'
    'data' # aux data
    'code' # our error code
    'form'
    'url'
    'headers'
    'statusCode'
    'bodySample'
    'bodyLength'
    'bodyFull'
    'action'
]

normalizeError = (error) ->
    if _.isObject error
        errorData = _.pick(error, possibleErrorProperties)
        if error.body and not error.bodySample
            errorData.bodySample = error.body.slice(0, MAX_BODY_LENGTH)
            errorData.bodyLength = error.body.length
            errorData.bodyFull = error.body.length < MAX_BODY_LENGTH
    else
        if _.isString error
            message = error
        else
            message = 'Unknown error'
        stack = null
        errorData = {stack, message}
    return errorData

module.exports = {SiteError, ExternalError, UnauthorizedError, normalizeError}