_ = require 'lodash'

module.exports = (value, field) ->

    val = value
    val = val.trim() if _.isString val

    if (field.key == 'wantedAge')
        val = parseInt(value)
        return {query: {wantedAgeFrom: {$lte: val}, wantedAgeTo: {$gte:val}}}

    if (val == 'empty' or val == 'E')
        return { value: $in: ['', null ] }

    if (val == 'non-empty' or val == '!E')
        return { value: $nin: ['', null ] }

    if (field.type == 'number')
        val = parseFloat(value)
        return {error: 'NaN'} if (isNaN(val))

    if (field.type == 'date' && field.viewFormat)
        return {value: {$gte:moment(value, field.viewFormat).startOf('day').toDate(), $lte:moment(value, field.viewFormat).endOf('day').toDate()}}

    if (field.type == 'text')
        return {value: { $regex: val, $options: 'i' } }

    return {value:val}