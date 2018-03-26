mongoose = require 'mongoose'
_ = require 'lodash'
Promise = require 'bluebird'

sessionSchema = mongoose.Schema(
    site: String
    username: type: String
    cookies: [String]
)

module.exports = mongoose.model 'Session', sessionSchema
