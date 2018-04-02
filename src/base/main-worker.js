import Position from '../db/position.coffee'
import _ from 'lodash'
import moment from 'moment'
import {takeText, parseImages, parseTotal} from './parse.js'
import Promise from 'bluebird'
import proxies from './proxies.coffee'
const unknown = '?'
function forceGC(){
    if (global.gc) {
        global.gc();
    } else {
        console.warn('No GC hook! Start your program as `node --expose-gc file.js`.');
    }
}

export default class MainWorker {
    constructor({term, maxJobs, delay}={}){
        console.log('Created global parser: ', term)
        this.term = term
        this.totalPages = unknown
        this.jobs = []
        this.fetched = 0
        this.page = 0 // pointer
        this.maxJobs = maxJobs || 100
        this.delay = delay || 200
        this.startMoment = moment()
        this.fetchedPages = [] // much memory
        this.failedPages = []
    }
    startPromise(){
        return proxies.init()
    }
    cycle(cycleN){
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
            Promise.delay(this.delay*n).then(()=>this.nextJob())
        })
        return Promise.delay(11000).then(()=>{return {result: max}})
    }
    info(){
        return this.fetched + '/' + this.totalPages
    }
    inspect({cycleN}){
        console.log({cycleN, term: this.term, page:this.page, total:this.totalPages, fetched:this.fetched, pages: this.fetchedPages, progress: this.progress()})
    }
    progress(){
        if (unknown == this.totalPages)
            return 0
        return this.fetched/this.totalPages*100
    }
    nextPage(){
        this.page++
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
        let url = '/search?searchterm='+this.term+'&search_source=base_search_form&language=en&page='+page+'&sort=popular&image_type=vector&measurement=px&safe=true'
        let promise = proxies.fetchPage(url)
            .catch((err)=>{
                console.error('Failed to fetch page: ' + page, err)
                this.failedPages.push(page)
            })
            .then(({$})=>{
                this.fetched++
                this.fetchedPages.push(page)
                let images = parseImages($, page-1)
                if (this.totalPages == unknown){
                    this.totalPages = parseTotal($)
                }
                this.page = page
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
                        console.log('JOB TIME', {seconds: moment().diff(jobStart, 'seconds')})
                        forceGC()
                    })
            })
        let job = {page, url, promise}
        this.jobs.push(job)
        return job.promise
    }
    save(){

    }
    

}
