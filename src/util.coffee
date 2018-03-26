cheerio = require 'cheerio'
cheerioAdv = require('cheerio-advanced-selectors')
cheerio = cheerioAdv.wrap(cheerio)

prepend = (message, prepend, separator) ->
    message ?= ''
    separator = ' '
    return message if not prepend or message == prepend
    return prepend + separator + message

logStream = (name, $) -> $.addListener next: (item) -> console.log name, item


module.exports = {prepend, cheerio, logStream}