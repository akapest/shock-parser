mongoose = require 'mongoose'
_ = require 'lodash'

positionSchema = mongoose.Schema(
    id: {type: String, required:true, unique:true} # md5 hash of source
    term: {type: String, required:true} # "global" / "portfolio" / keyword
    position: {type:Number}
    date: {type:Date, required:true, index:true}
)

#imageSchema.index({siteId: 1, login: 1}, {unique: true})

module.exports = mongoose.model 'Position', positionSchema
