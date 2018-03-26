import Vue from 'vue'
import VueRouter from 'vue-router'
import moment from 'moment'
moment.locale('ru')

import App from './App.vue'
import Portfolios from './components/Portfolios.vue'

Vue.use(VueRouter)

var router = new VueRouter({
    routes: [
        { path: '/', component: App },
        { path: '/profiles', component: Portfolios }
    ]
})
Vue.config.errorHandler = function (err, vm, info) {
    console.log(err)
}
process.on('uncaughtException', (err) => console.error('Uncaught error: ' + err.message, err, {stack:err.stack}))
process.on('unhandledRejection', (err) => console.error('Unhandled rejection: ' + err.message, err, {stack:err.stack}))


const app = new Vue({
    router
}).$mount('#app')