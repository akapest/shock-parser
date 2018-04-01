console.log('start')
Worker = require('./main-worker.js').default
expect = require('chai').expect

describe 'MAIN WORKER', () ->

    it 'should be able to get proxies', (done) ->

        worker = new Worker({})
        console.log('start')
        pm = worker.startPromise()
        pm.then ->
            console.log('STARTED')
            proxy = worker.nextProxy()
            expect(proxy).to.be.not.null
            done()

    xit 'should fetch and save positions', (done) ->

        worker = new Worker({term:'vector'})
        worker.startPromise()
        .then ->
            worker.nextJob()

    xdescribe 'nextPage', ->
        it 'starts from 1', ->
            worker = new Worker()
            expect(worker.nextPage()).to.be.equal 1

        it 'iterates by 1', ->
            worker = new Worker()
            expect(worker.nextPage() - worker.nextPage()).to.be.equal -1

        it 'should return pages in random order omitting same messages', ->







