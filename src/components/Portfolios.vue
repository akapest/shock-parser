<template>
    <div v-if="show">
        <table class="table-cols-3 mhm">
            <thead>
                <tr>
                    <th>Id</th>
                    <th>Создан</th>
                    <th>Обновлен</th>
                    <th>Число изображений</th>
                    <th></th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="item in portfolios">
                    <td v-if="isModifiable(item)"><editable @change="update(item, $event)" :field="{key: 'name'}" :value="item.name"></editable></td>
                    <td v-if="!isModifiable(item)">{{item.name}}</td>
                    <td>{{timeView(item.createdAt)}}</td>
                    <td>{{timeView(item.updatedAt)}}</td>
                    <td>{{item.imagesCount}}</td>
                    <td><button @click="updatePortfolio(item)" :disabled="item.fetch.running">
                            <span v-if="!item.fetch.running" class="icon icon-download" title="Спарсить изображения"></span>
                            <span v-if="item.fetch.running">{{item.fetch.page}}/{{item.fetch.total}}</span>
                        </button>
                    </td>
                    <td><button @click="removeAccount(item)"><span class="icon icon-cancel" title="Удалить портфолио"></span></button></td>
                </tr>
            </tbody>
        </table>
        <div class="mhm">
            <button class="bttn" @click="addAccount">Добавить</button>
            <!--<button class="bttn" @click="remove">Remove all portfolios</button>-->
        </div>
        <div class="mhm">
            <runner :runnableFactory="getGlobalParser"/>
        </div>
    </div>
</template>

<script>
    import db from '../db/api.coffee'
    import Portfolio from '../db/portfolio.coffee'
    import Image from '../db/image.coffee'
    import editable from './editable.vue'
    import _ from 'lodash'
    import moment from 'moment'
    const defaultName = ''
    import ExternalSite from '../base/external-site.coffee'
    import {parseImages, parseTotal} from '../base/parse.js'
    import MainWorker from '../base/main-worker.js'

    let shutter = new ExternalSite({
        id: 'SS',
        domain: 'shutterstock.com',
        url: 'https://www.shutterstock.com',
    })
    function defaultFetch(){ return  {running: false, page: 0, total: '?'} }

    export default {
        data(){
            return {portfolios:[], show:true}
        },
        components: {editable},
        watch: {
        },
        mounted(){
            this.getPortfolios()
        },
        methods: {
            isModifiable(item){
                return item.name == defaultName
            },
            timeView(datetime){
                if (!datetime) {
                    return 'Изображения не собраны'
                }
                return moment(datetime).fromNow()
            },
            addAccount(){
                let query = {name: defaultName, createdAt: new Date()}
                db.create(Portfolio, query)
                .then((item) => {
                    item.fetch = defaultFetch()
                    this.portfolios.push(item)
                })
            },
            getPortfolios(){
                db.get(Portfolio, {query: {}})
                .then((result) => {
                    _.each(result, (item)=>{
                        item.fetch = defaultFetch()
                    })
                    let args = [0, this.portfolios.length]
                    args = args.concat(result)
                    this.portfolios.splice.apply(this.portfolios, args)
                    this.rerender()
                })
            },
            update(account, {field, value}){
                let key = field.key
                account = JSON.parse(JSON.stringify(account))
                if (key == 'name') {
                    if (value.indexOf('/')) {
                        let array = value.split('/')
                        value = array[array.length-1]
                    }
                }
                let query = {_id: account._id}
                let $set = {}
                $set[key] = value
                db.update(Portfolio, {query, $set, options:{upsert:true}})
                .then(()=>{
                    this.getPortfolios()
                })
            },
            removeAccount(account){
                let confirm = window.confirm('Remove account?')
                if (!confirm) return;
                db.remove(Portfolio, {_id: account._id})
                .then(()=>{
                    this.getPortfolios()
                })
            },
            rerender(){
                this.show = false
                this.$nextTick(() => {
                    this.show = true
                })
            },
            updatePortfolio(portfolio){
                portfolio.fetch = defaultFetch()
                portfolio.fetch.running = true
                shutter.getPage('/g/' + portfolio.name) // todo error / retry?
                .then(({$})=>{
                    portfolio.fetch.total = parseTotal($)
                    return this.parseNsaveImages($, portfolio)
                    .then(()=> {
                        portfolio.fetch.page = 1
                        return this.fetchNextImagesPage(portfolio)
                    })
                })
                this.rerender()
            },
            fetchNextImagesPage(portfolio){
                let page = portfolio.fetch.page + 1
                if (page > portfolio.fetch.total) {
                    portfolio.fetch.running = false
                    return
                }
                this.rerender()
                shutter.getPage('/g/'+portfolio.name+'?sort=popular&search_source=base_gallery&language=en&page=' + page)
                .then(({$})=> {
                    return this.parseNsaveImages($, portfolio)
                    .then(()=> {
                        portfolio.fetch.page = page
                        return this.fetchNextImagesPage(portfolio)
                    });
                })
            },
            parseNsaveImages($, portfolio){
                let images = parseImages($, portfolio.fetch.page, portfolio)
                return db.saveItems(Image, images) // todo error
                .then(()=>{
                    return db.count(Image, {query: {portfolioId: portfolio.name}})
                    .then((result)=>{
                        portfolio.imagesCount = result
                        portfolio.updatedAt = new Date()
                        this.rerender()
                        return db.update(Portfolio, {query: {name:portfolio.name}, $set:{imagesCount:result, updatedAt: new Date()}})
                    })
                })
            },
            getGlobalParser(){
                return new MainWorker({term:'vector'})
            },

        }
    }
</script>

<style>
.table-cols-3 th {
    width: 30%;
}
</style>