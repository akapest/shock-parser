_ = require 'lodash'
moment = require 'moment'
bus = require '../bus.coffee'
editable = require './editable.vue'
db = require '../db/api.coffee'

format = (value, type) ->
#    return '' if typeof(value) == 'undefined'
    if type == 'date'
        return moment(value).format('YYYY-MM-DD')
    if _.isArray value
        if value.length
            return JSON.stringify(value)
        else
            return ''

    return '' if value == undefined
    return '' if value == null
    return value

imgrgx = /.*image.*/i

module.exports = (createElement, object, site) ->

        object ?= {}
        fields = site.entities.ad.fields
        url = site.xhrUrl || site.url

        fullUrl = (value) ->
            if _.isFunction(url)
                return url(value)
            else
                return url + value

        keys = _.filter(_.keys(fields), (key) -> not site.entities.ad.fields[key].noTable)

        typeClass = (f) ->
            classes = {}
            classes[f.type] = true
            return classes

        createElement 'tr', _.map keys, (key) ->
            f = fields[key]
            f.key = key

            value = _.get object, key if ! _.isFunction f.value
            value = f.value(object) if _.isFunction f.value

            type = 'string'
            type = 'image' if value and imgrgx.test key
            type = 'imageData' if value and key.indexOf('images') == 0
            type = 'link' if key == 'href' or key == 'link'
            type = 'hhref' if key == 'hhref'
            type = f.type if f.type

            href = fullUrl(value)
            click = (e) ->
                bus.$emit('new:page', href)
                e.preventDefault()

            change = ({field, value}) ->
                $set = _.set {}, field.key, value
                db.update site.getAdEntity(), {query: {id: object.id}, $set}
            image = (raw) ->
                b64 = btoa(raw)
#                console.log {key, raw, b64}
                return "data:image/png;base64," + b64

            element = if f.editable then createElement 'editable', {props: {field: f, siteId: site.id, value: value}, on: {change}}
            element ?=
                switch type
                    when 'string' then createElement 'span', {attrs: {title: value}}, format(value, type)
#                    when 'image' then createElement 'img', {attrs: src: fullUrl value}
                    when 'image' then createElement 'a', {on: {click}, attrs: {href}}, href
                    when 'imageData' then createElement 'img', {attrs: src: image(value)}
                    when 'imageFullUrl' then createElement 'img', {attrs: src: value}
                    when 'link' then createElement 'a', {on: {click}, attrs: {href}}, value
                    when 'hhref' then createElement 'a', {on: {click}, attrs: {href:value}}, value
                    when 'text' then createElement 'div', {class: typeClass(f),attrs: {title: value}}, format(value, type)
                    else createElement 'span', format(value, type)

            createElement 'td', {  }, [ element ]


