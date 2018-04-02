mongoose = require 'mongoose'
_ = require 'lodash'

positionSchema = mongoose.Schema(
    imageId: {type: String, required:true} # md5 hash of source
    globalVector: {type: Boolean, default:false}
    term: {type: String} # keyword
    position: {type:Number}
    date: {type:Date, required:true, index:true}
)

#imageSchema.index({siteId: 1, login: 1}, {unique: true})

module.exports = mongoose.model 'Position', positionSchema
