
FetchPlanner = require './fetch-planner.coffee'
expect = require('chai').expect

describe 'FetchPlanner', ->

    it 'should process all the pages', ->
        total = 130
        segments = 10
        planner = new FetchPlanner({total, segments})
        console.log planner
        i = 0
        {page, segment} = planner.next()
        while (page)
            i++
            {page} = planner.next()
        expect(i).to.be.equal(total)


    it 'should get items by one from segments', ->
        total = 30
        segments = 3
        planner = new FetchPlanner({total, segments})
        expect(planner.next().page).to.be.equal 1
        expect(planner.next().page).to.be.equal 11
        expect(planner.next().page).to.be.equal 21
        expect(planner.next().page).to.be.equal 2
