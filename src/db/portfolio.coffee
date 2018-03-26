mongoose = require 'mongoose'
_ = require 'lodash'


accSchema = mongoose.Schema(
    name: {type: String, unique:true}
    createdAt: {type:Date}
    updatedAt: {type:Date}
    images: {type:Array}
    imagesCount: {type:Number}
)

#accSchema.index({siteId: 1, login: 1}, {unique: true})

module.exports = mongoose.model 'Portfolio', accSchema
