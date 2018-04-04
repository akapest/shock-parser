import Position from '../db/position.coffee'
import _ from 'lodash'
import moment from 'moment'
import {takeText, parseImages, parseTotal} from './parse.js'
import Promise from 'bluebird'
import proxies from './proxies.coffee'
function forceGC(){
    if (global.gc) {
        global.gc();
    } else {
        console.warn('No GC hook! Start your program as `node --expose-gc file.js`.');
    }
}
const unknown = '?'
export default class MainWorker {
    constructor({term, maxJobs, delay}={}){
        console.log('Created global parser: ', term)
        this.term = term
        this.totalPages = unknown
        this.jobs = []
        this.fetched = 0
        this.page = 0 // pointer
        this.maxJobs = maxJobs || 1000
        this.delay = delay || 200
        this.pagesToFetch = [] // from - to
        this.fetchedPages = [] // much memory
        this.failedPages = []
    }
    startPromise(){
        return proxies.init({sitesPerProxy:3, pagesPerProxy:20})
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
        return Promise.delay(5000).then(()=>{return {done: false, result: max || 'skip'}})
    }
    info(){
        return this.fetched + '/' + this.totalPages + '   ' + ((this.fetched+this.failedPages.length)/moment().diff(this.startMoment, 'seconds')) + ' rps'
    }
    inspect({cycleN}){
        console.log('CYCLE', {cycleN, term: this.term, page:this.page, total:this.totalPages, fetched:this.fetched, failed: this.failedPages, pages: this.fetchedPages, progress: this.progress()})
    }
    progress(){
        if (unknown == this.totalPages)
            return 0
        return this.fetched/this.totalPages*100
    }
    nextPage(){
        this.page++
        if (this.page >= this.totalPages) {
            let page = this.failedPages.unshift()
            console.log('refetch failed page', + page)
            return this.failedPages.unshift()
        }
        return this.page
        // let page = Math.random() * this.totalPages
        // this.pages.push(page)
        // return page
    }
    nextJob(){
        if (this.jobs.length >= this.maxJobs){
            return Promise.resolve()
        }
        let page = this.nextPage()
        if (page > this.totalPages) {
            return Promise.resolve()
        }
        let jobStart = moment()
        let url = '/search?searchterm='+this.term+'&search_source=base_search_form&language=en&page='+page+'&image_type=vector'
        let promise = proxies.fetchPage(url)
            .catch((err)=>{
                console.error('Failed to fetch page: ' + page, err)
                this.failedPages.push(page)
            })
            .then(({$})=>{
                this.fetched++
                this.fetchedPages.push(page)
                this.fetchedPages.sort((a, b) => a - b)
                let images = parseImages($, page-1)
                if (this.totalPages == unknown){
                    this.totalPages = parseTotal($)
                }
                if (!images.length){
                    console.error('Failed to fetch items, page: ' + page)
                    this.failedPages.push(page)
                }
                let positions = _.map(images, ({id, position})=>{return {imageId:id, globalVector:true, term:null, position, date:new Date()}})
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
