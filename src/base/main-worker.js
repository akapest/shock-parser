import Position from '../db/position.coffee'
import _ from 'lodash'
import moment from 'moment'
import ExternalSite from './external-site.coffee'
import {takeText, parseImages, parseTotal} from './parse.js'

import Promise from 'bluebird'
import proxies from './proxies.coffee'
const unknown = '?'
export default class MainWorker {
    constructor({term, maxJobs, delay}={}){
        console.log('Created global parser: ', term)
        this.term = term
        this.totalPages = unknown
        this.jobs = []
        this.fetched = 0
        this.page = 0 // pointer
        // this.fetchedPages = [] // much memory
        this.maxJobs = maxJobs || 10
        this.delay = delay || 200
        this.startMoment = moment()
        this.failedPages = []
    }
    startPromise(){
        return proxies.init()
    }
    cycle(cycleN){
        this.inspect({cycleN})
        this.cycleStart = moment()
        if (this.fetched == this.totalPages){
            if (!this.endMoment) {
                this.endMoment = moment()
                console.log('TIME', {minutes: this.endMoment.diff(this.startMoment, 'minutes')})
            }
            return {done:true}
        }
        return Promise.map(_.range(1, this.maxJobs), (n) => {
            return Promise.delay(this.delay*n).then(()=>this.nextJob())
        }).then((jobs)=>{
            console.log('CYCLE TIME', {minutes: moment().diff(this.startMoment, 'minutes')})
            return {done:false, result: jobs}
        })
    }
    info(){
        return this.fetched + '/' + this.totalPages
    }
    inspect({cycleN}){
        console.log({cycleN, term: this.term, page:this.page, total:this.totalPages, fetched:this.fetched, progress: this.progress()})
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
        let url = '/search?searchterm='+this.term+'&search_source=base_search_form&language=en&page='+page+'&sort=popular&image_type=vector&measurement=px&safe=true'
        let promise = proxies.fetchPage(url)
            .then(({$})=>{
                this.fetched++
                let images = parseImages($, page-1)
                if (page == 1){
                    this.totalPages = parseTotal($)
                }
                this.page = page
                let positions = _.map(images, ({id, position})=>{return {_id:id, globalVector:true, term:null, position, date:new Date()}})
                return Position.insertMany(positions)
                    .then((result)=>{
                        let i = _.findIndex(this.jobs, (j)=>{return j.page == page})
                        this.jobs.splice(i,1)
                        return {positions, result}
                    })
            })
            .catch((e)=>{
                this.failedPages.push(page)
            })
        let job = {page, url, promise}
        this.jobs.push(job)
        return job
    }
    

}
