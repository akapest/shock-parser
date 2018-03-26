db = require('./db.coffee')
path = require 'path'
_ = require 'lodash'
Promise = require 'bluebird'

count = (Entity, {query}) =>
    db.execute (done) => Entity.count.call(Entity, query, done)

create = (Entity, $set) ->
    db.execute (done) =>
        return Entity.create.call(Entity, $set, done)
    .then (result) ->
        console.log 'CREATE', result
        return result

update = (Entity, {query, $set, $setOnInsert, $addToSet, $push, $unset, options}) ->
    throw new Error('No query') if not query
    options ?= {upsert: true}
    db.execute (done) =>
        console.warn('$set and $unset at the same time') if ($set or $setOnInsert) and $unset
        $update = {} if not $unset
        $update.$set = $set if $set
        $update.$setOnInsert = $setOnInsert if $setOnInsert
        $update.$push = $push if $push
        $update.$addToSet = $addToSet if $addToSet
        q = Entity.update.call(Entity, query, $update, options) if $update
        q = Entity.update.call(Entity, query, {$unset}, options) if $unset
        q.exec(done)
        return q
    .then (result) ->
        console.log 'UPDATE', result
        return result

get = (Entity, {query, projection, options}) ->
    throw new Error('No query') if not query
    db.execute (done) -> Entity.find.call(Entity, query, projection, options, done)

getOne = (Entity, params) ->
    get(Entity, params)
    .then (results) -> return results?[0]

remove = (Entity, query) ->
    db.execute (done) -> Entity.remove.call(Entity, query, done)

saveItems = (Entity, items) ->
    Promise.map items, (item) =>
        return Promise.resolve() if not item
        update Entity, {query:{id:item.id}, $set: item, options: {upsert: true}}
    , {concurrency: 20}

module.exports = { get, getOne, count, create, update, remove, saveItems }