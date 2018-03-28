<template>
    <div class="mvs">
        <button class="bttn bttn-primary" @click="toggle()" :disabled="toggleDisabled">{{actionName()}}</button>
        <span v-show="state == 'running'">{{runnable.info(cycleNumber)}}</span>
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
        props: ['runnableFactory', 'info'],
        data(){
            return {state:'idle', cycleNumber: 0, lastResult: '', runnable:{info:()=>{}}}
        },
        computed:{
            toggleDisabled(){
                return (this.state == 'starting' || this.state == 'stopping')
            },
        },
        methods: {
            actionName(){
                if (this.state == 'running' || this.state == 'starting') return 'Остановить'
                if (this.state == 'idle' ||  this.state == 'stopping') return 'Начать сбор'
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
                .then(({error, done, result}={}) => {
                    this.cycleNumber++
                    if (!error && !done && !result){
                        alert('Cycle result should contain one of props from {error,  done, result}') // dev error
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
                this.runnable = this.runnableFactory()
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