import Position from '../db/position.coffee'
import _ from 'lodash'
import moment from 'moment'
import {takeText, parseImages, parseTotal} from './parse.js'
import Promise from 'bluebird'
import proxies from './proxies.coffee'
import Planner from './fetch-planner.coffee'
function forceGC(){
    if (global.gc) {
        global.gc();
    } else {
        console.warn('No GC hook! Start your program as `node --expose-gc file.js`.');
    }
}
import db from '../db/api.coffee'
import Image from '../db/image.coffee'

let imagesIds = [] 

db.get(Image, {query: {}, options:{sort:{position:1}}})
.then((results)=>{
    imagesIds = results.map((item) => item.id)
})
let found = 0
function round(n, digits){
    digits = digits || 2
    let tens = Math.pow(10, digits)
    return Math.round(n * tens) / tens

}
function getPositions(images, term){
    let filtered = _.filter(images, ({id})=> imagesIds.indexOf(id) >= 0)
    if (filtered.length) {
        found += filtered.length
    }
    let date = new Date()
    let day = moment().dayOfYear()
    return _.map(filtered, ({id, position})=>{return {imageId:id, term, position, date, day}})
}

const unknown = '?'
export default class MainWorker {
    constructor({term, maxJobs, delay}={}){
        console.log('Created global parser: ', term)
        let offset = 146000, total = 147000
        this.term = term
        this.totalPages = total - offset
        this.last = total
        this.jobs = []
        this.fetched = 0
        this.maxJobs = maxJobs || 100
        this.fetchedPages = []
        this.failedPages = []
        this.planner = new Planner({offset, total, segments:10})
    }
    startPromise(){
        return proxies.init({sitesPerProxy:2, pagesPerProxy:20})
            // .then(()=>this.nextJob({direct:true}))
    }
    info(){
        return [this.progress({str:true}), this.rps(), this.time(), this.found()].join(', \t')
    }
    time(){
        if (!this.startMoment) return proxies.info()
        return round(moment().diff(this.startMoment, 'seconds')/60) + 'mins'
    }
    found(){
        return 'found: ' + found
    }
    rps(){
        return round((this.fetched+this.failedPages.length)/moment().diff(this.startMoment, 'seconds')) + ' rps'
    }
    progress({str}={}){
        if (str){
            return this.fetched + '/' + this.totalPages
        }
        if (unknown == this.totalPages)
            return 0
        return this.fetched/this.totalPages*100
    }
    inspect({cycleN}){
        console.log('CYCLE', {cycleN, info: this.info(), found, term: this.term, fetched:this.fetched, failed: this.failedPages, pages: this.fetchedPages, progress: this.progress()})
    }
    cycle(cycleN){
        if (!this.startMoment){
            this.startMoment = moment()
        }
        this.inspect({cycleN})
        if (this.fetched == this.totalPages){
            if (!this.endMoment) {
                this.endMoment = moment()
                console.log('TIME', {minutes: this.endMoment.diff(this.startMoment, 'minutes')})
            }
            return {done:true}
        }
        let max = this.maxJobs - this.jobs.length
        _.each(_.range(0, max), (n) => {
            Promise.delay(5).then(()=>this.nextJob())
        })
        forceGC()
        return Promise.delay(5000).then(()=>{return {done: this.done, result: max || 'skip'}})
    }
    nextJob({direct}={}){
        if (this.jobs.length >= this.maxJobs){
            return Promise.resolve()
        }
        let page=1, segment
        if (this.planner) {
            let next = this.planner.next()
            if (next) {
                page = next.page
                segment = next.segment
                if (page > this.last || ! page) {
                    this.done = true
                    return Promise.resolve()
                }
            } else {
                return Promise.resolve()
            }
        }
        let jobStart = moment()
        let url = '/search?searchterm='+this.term+'&search_source=base_search_form&language=en&page='+page+'&image_type=vector'
        let promise = proxies.fetchPage(url, {direct})
            .catch((err)=>{
                console.error('Failed to fetch page: ' + page, err)
                this.failedPages.push(page)
            })
            .then(({$})=>{
                this.fetched++
                this.fetchedPages.push(page)
                this.fetchedPages.sort((a, b) => a - b)
                let images = parseImages($, page-1)
                // if (this.totalPages == unknown){
                //     this.totalPages = parseTotal($)
                // }
                if (!images.length){
                    console.error('Failed to fetch items, page: ' + page)
                    this.failedPages.push(page)
                }
                let positions = getPositions(images)
                if (segment) {
                    segment.addFound(positions.length)
                }
                return Position.insertMany(positions)
                    .then((result)=>{
                        return {result}
                    })
                    .catch((err)=>{
                        console.error('Failed to save items, page: ' + page, err)
                        this.failedPages.push(page)
                    })
                    .finally(()=>{
                        let i = _.findIndex(this.jobs, (j)=>{return j.page == page})
                        this.jobs.splice(i,1)
                        console.log('JOB TIME', job, {l: images.length, seconds: moment().diff(jobStart, 'seconds')})
                    })
            })
        let job = {page, url, promise}
        this.jobs.push(job)
        console.log('JOBS length', this.jobs.length)
        return job.promise
    }
    save(){

    }
    

}
