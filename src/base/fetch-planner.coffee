_ = require 'lodash'

class Segment
    constructor: ({@first, @last}={}) ->
        @current = @first-1
        @found = 0

    next: ->
        @current++
        if @current > @last
            return null
        return @current

    addFound: (n) ->
        @found += n

class FetchPlanner

    constructor: ({@total, segments, offset}={}) ->
        offset ?= 0
        @segments = []
        @pointer = -1
        perSegment = Math.ceil(@total / segments)
        for i in [0..segments]
            first = offset + i*perSegment + 1
            last = Math.min(first + perSegment - 1, @total)
            if last >= first
                @segments.push(new Segment({first, last}))

    nextSegment: ->


    next: ->
        sorted = _.sortBy(@segments, (s) -> -s.found)
        @pointer++
        p = @pointer
        if p >= sorted.length
            p = @pointer = 0
        s = @segments[p]
        page = s.next()
        console.log {p, page}
        return {page, segment:s}




module.exports = FetchPlanner