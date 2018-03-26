
<template>
    <div :class="{ editable: true, 'editable-show': !inEdit}" @click="toEditMode">
        <label v-if="field.label && (!options || !options.supressLabel)">{{field.label}}</label>
        <div v-if="inEdit">
            <input v-if="field.type == 'number'" v-model="value_" v-focus
                        @blur="done"
                        @keyup.esc="cancel"
                        @keyup.enter="done"
                    type="number" min="1" />
            <textarea v-if="field.type == 'text'" v-model="value_" @blur="done" style="width:400px;height: 120px"
                        @keyup.esc="cancel"
                        @keyup.enter="done"></textarea>
            <input v-if="field.type == 'string' || !field.type" v-model="value_" v-focus
                        @blur="done"
                        @keyup.esc="cancel"
                        @keyup.enter="done"/>
            <select v-if="field.type == 'select'" v-model="value_" :multiple="field.multi"
                        @blur="done"
                        @keyup.esc="cancel"
                        @keyup.enter="done">
                <option v-for="item in selectValues(field)">
                    {{item}}
                </option>
            </select>
        </div>
        <div v-if="!inEdit" class="pxs pvm trnstn">{{value_}}</div>
    </div>
</template>

<script>
    import parseValue from './parse-value.coffee'
    export default {
        props: ['field', 'siteId', 'value', 'options'],
        data () {
            return {
                inEdit: false,
                value_: this.value
            }
        },
        methods: {
            selectValues(field){
                if (_.isFunction(field.values)){
                    return field.values(this.siteId)
                }
                return field.values
            },
            toEditMode () {
                if (this.inEdit) return
                this.inEdit = true
                this.prev = this.value_ // clone ?
            },
            done () {
                this.inEdit = false
                let {value, error} = parseValue(this.value_, this.field)
                if (error){
                    this.cancel()
                } else {
                    this.$emit('change', {value, field: this.field})
                }
            },
            cancel () {
                this.inEdit = false
                this.value_ = this.prev
            },
        }
    }
</script>

<style>
.editable{
    display:inline-block;
    border: 1px rgba(33, 33, 33, 0.2);
    cursor: pointer;
    min-height: 32px;
    min-width: 100px;
}
.editable > div{
    display:inline-block;
}
.editable-show{
    border: 1px dashed transparent;
    cursor: pointer;
}
.editable-show:hover{
    border: 1px dashed rgba(33, 33, 33, 0.2);
    background: rgba(33, 33, 33, 0.2);
}
</style>