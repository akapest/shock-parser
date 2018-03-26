<template>
    <div class="mvs">
        <button class="bttn bttn-primary" @click="toggle()" :disabled="disabled || toggleDisabled">{{actionName()}}</button>
        <span v-show="state == 'running'">cycle: {{cycleNumber}} {{lastResult}}</span>
    </div>
</template>
<script>
    import Promise from 'bluebird'
    import _ from 'lodash'
    let ensure = (runnable, fnName) => {
        let promiseFn = runnable[fnName]
        if (promiseFn && _.isFunction(promiseFn)) {
            return promiseFn.call(runnable)  
        } else if (promiseFn) {
            return Promise.resolve(promiseFn)
        }
        return Promise.resolve()
    }
    export default {
        props: ['runnableFctry', 'name', 'disabled'],
        data(){
            return {state:'idle', cycleNumber: 0, lastResult: ''}
        },
        computed:{
            toggleDisabled(){
                return (this.state == 'starting' || this.state == 'stopping')
            },
        },
        methods: {
            actionName(){
                if (this.state == 'running' || this.state == 'starting') return 'stop'
                if (this.state == 'idle' ||  this.state == 'stopping') return 'start'
                throw new Error('Unexpected run state: ' + this.state)
            },
            errorHandler(err){
                this.state = 'idle'
                this.$emit('error', err)
            },
            setState(state){
                this.state = state
                this.$emit('stateChange', state)
            },
            toggle(){
                if (this.state == 'idle') { this.startCycling() }
                else if (this.state == 'running') { this.stopCycling() }
                else { console.log('Ingore toggle', {state:this.state}) }
            },
            runNextCycle() {
                return this.runnable.cycle.call(this.runnable, this.cycleNumber)
                .then(({error, done, result}) => {
                    this.cycleNumber++
                    if (!error && !done && !result){
                        throw new Error('Cycle result should contain one of props from {error,  done, result}')
                    }
                    if (error) {
                        this.$emit('error', error)
                        return;
                    }
                    this.$emit('cycleEnd', result)
                    if (done || this.state != 'running') {
                        this.stopCycling()
                    } else {
                        this.lastResult = result
                        this.setState('running')
                        return this.runNextCycle(this.cycleNumber)
                    }
                })
                .catch(this.errorHandler)
            },
            startCycling(){
                this.cycleNumber = 0
                this.lastResult = ''
                this.runnable = this.runnableFctry()
                this.setState('starting')
                ensure(this.runnable, 'startPromise').then(()=>{
                    this.setState('running')
                    return this.runNextCycle()
                })
                .catch(this.errorHandler)
            },
            stopCycling(){
                this.setState('stopping')
                ensure(this.runnable, 'stopPromise').then(()=>{
                    this.setState('idle')
                })
                .catch(this.errorHandler)
            },

        }
    }
</script>


<style>
</style>