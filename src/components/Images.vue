<template>
    <div v-if="show">
        <div class="mbl">
            <select v-model="portfolio" @change="onChange">
                <option v-for="p in portfolios" :value="p">{{p.name}}</option>
            </select>
        </div>
        <pagination :records="images.length" @paginate="pageChange" :per-page="100"></pagination>
        <div class="images-row" v-if="images.length" v-for="i in 10">
            <div v-for="j in 10" v-if="hasImage(i,j)">
                <img class="images-list-image"  :src="imageSource(i,j)"/>
                <!--<span style="padding:2px;">{{getPosition(i,j)}}</span>-->
            </div>
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
    import ExternalSite from '../base/external-site.coffee'
    import crypto from 'crypto'

    export default {
        data(){
            return {portfolio: null, portfolios:[], images:[], show:true, page:1}
        },
        components: {editable},
        watch: {
            portfolio(next){
                this.getImages(next)
            }
        },
        mounted(){
            this.getPortfolios()
        },
        methods: {
            image(i,j){
                let n = (this.page-1)*100 + (i-1)*10 + j
                return this.images[n-1]
            },
            hasImage(i, j){
                return !!this.image(i,j)
            },
            imageSource(i, j){
                return this.image(i,j).source.replace('//', 'https://')
            },
            getPosition(i,j){
                return ' ' + this.image(i,j).position + ' '
            },
            replaceArray(array, next){
                let args = [0, array.length]
                args = args.concat(next)
                array.splice.apply(array, args)
                this.rerender()
            },
            getPortfolios(){
                db.get(Portfolio, {query: {}})
                .then((result) => {
                    this.portfolio = result[0]
                    this.replaceArray(this.portfolios, result)
                })
            },
            getImages(portfolio){
                db.get(Image, {query: {portfolioId: portfolio.name}, options:{sort:{position:1}}})
                .then((result)=>{
                    this.replaceArray(this.images, result)
                })
            },
            onChange(){
                this.page = 1
            },
            pageChange(v){
                this.page = v
            },
            rerender(){
                this.show = false
                this.$nextTick(() => {
                    this.show = true
                })
            },

        }
    }
</script>

<style>
.table-cols-3 th {
    width: 30%;
}
.images-list-image{
    height:100px;
    width:100px;
}
.images-row > div {
    float:left;
}
</style>