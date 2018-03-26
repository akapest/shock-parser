<template>
    <div class="filter">
        <div class="mhs">
            <span>Filter by: </span>
            <button class="bttn bttn-stndrd" style="height:24px" @click="addRow()">+</button>
            <button class="bttn bttn-stndrd" style="height:24px" v-tooltip="{content:content}">?</button>
        </div>
        <div v-for="(item, index) in rows">
            <select v-model="item.field" @change="onChange">
                <option v-for="f in filtering" :value="f">{{f.name}}</option>
            </select>
            <input type="text" v-model="item.value" @blur="onChange">
            <button class="bttn bttn-stndrd" style="width:24px;" @click="removeRow(index)">-</button>
            <button class="bttn bttn-stndrd" @click="addRow()">+</button>
        </div>
    </div>

</template>
<script>
    import _ from 'lodash'
    import parseValue from './parse-value.coffee'

//    localStorage.clear()

    function getFiltering(fields){
        return _.compact(_.flatten(_.map(_.keys(fields), (key) => {
            let field = fields[key]
            if (field.filtering) {
                field.name = field.label || key
                field.key = key
                return field
            }
        })))
    }
    function getQuery(rows) {
        let l = rows.length
        let query = {}
        while (l--) {
            let {field, value} = rows[l]
            let parsed = parseValue(value, field)
            if (value || value === 0){
                if (!parsed.error) {
                    if (parsed.query) {
                        query = _.extend(query, parsed.query)
                    } else {
                        query[field.column || field.key] = parsed.value
                    }
                }
            }
        }
        console.log("QUERY", query)
        return query
    }

    export default {

        props: ['fields'],

        data () {
            return {rows:[], content: 'special values: "E"("empty") and "!E"("non-empty")'}
        },
        watch:{
            fields(){
                this.update()
            }
        },
        computed: {
            filtering(){
                return getFiltering(this.fields)
            }
        },
        mounted(){
            this.update()
        },
        methods: {
            update(){
                const rows = JSON.parse(localStorage.getItem('filter')) || []
                this.rows = _.compact(_.map(rows, (row) => {
                    const field = _.find(this.filtering, (f) => {
                        return f.key == row.key
                    })
                    if (field) return {field, value: row.value}
                    return null
                }))
                if (this.rows.length){
                    this.$emit('change', getQuery(this.rows))
                }
            },
            save(){
                const rows = _.map(this.rows, (row) => {
                    return {key: row.field.key, value: row.value}
                })
                localStorage.setItem('filter', JSON.stringify(rows))
            },
            onChange (){
                this.$emit('change', getQuery(this.rows))
                this.save();
            },
            addRow(){
                if (this.getNexEmptyField()){
                    this.rows.push({field:this.getNexEmptyField(), value:''})
//                    this.$emit('change', getQuery(this.rows))
                }
                this.save();
            },
            removeRow(index){
                this.rows.splice(index, 1)
                this.save();
                this.$emit('change', getQuery(this.rows))
            },
            getNexEmptyField(){
                let busy = _.map(this.rows, (row) => { return row.field })
                let avail = _.differenceBy(this.filtering, busy, (i1)=>{ return i1.name })
                if (avail.length) {
                    return avail[0]
                }
                return;
            }
        }
    }
</script>

<style>
body .tooltip {
    opacity: 1;
}
body .tooltip-inner{
    background-color:#334;
}
</style>