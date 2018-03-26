<template>
    <select v-model="selected" @change="onChange">
        <option v-for="f in sorting" :value="f">{{f}}</option>
    </select>
</template>
<script>
    import _ from 'lodash'

    let fields = {}

    function getSort(field) {
        let sort = {}
        if (field.indexOf('↓') > 0){
            sort[field.replace(' ↓', '')] = 1
        } else {
            sort[field.replace(' ↑', '')] = -1
        }
        return sort
    }
    function getSortingFields(fields){
        return _.compact(_.flatten(_.map(_.keys(fields), (name) => {
            if (fields[name].sorting) return [name + ' ↑', name + ' ↓']
            return null;
        })))
    }

    export default {

        props: ['fields'],

        data () {
            let sorting = getSortingFields(this.fields)
            return {sorting, selected: sorting[0]}
        },
        mounted(){
            this.onChange()
        },
        methods: {
            onChange (){
                this.$emit('change', getSort(this.selected))
            }
        }
    }
</script>

<style>
</style>