mongoose = require 'mongoose'
_ = require 'lodash'

imageSchema = mongoose.Schema(
    id: {type: String, required:true, unique:true} # md5 hash of source
    source: {type: String, required:true}
    link: {type: String, required:true}
    description: {type: String}
    portfolioId: {type: String} # portfolio name
    position: {type:Number}
)

#imageSchema.index({siteId: 1, login: 1}, {unique: true})

module.exports = mongoose.model 'Image', imageSchema
