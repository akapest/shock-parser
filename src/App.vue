    <template>
    <div class="app-title">
        <h1>{{ msg }}</h1>
        <!--<o2html :object="WGS"></o2html>-->
    </div>
</template>

<script>
//    import styles from './styles.scss'
    import o2html from './components/o2html.vue'
    import o2row from './components/o2row.vue'
    import editable from './components/editable.vue'
    import Vue from 'vue'
    import all from './directives.coffee'
    import {Pagination} from 'vue-pagination-2';
    import {Tabs, Tab} from 'vue-tabs-component';
    import lodash from 'lodash';
    import moment from 'moment';
    import VTooltip from 'v-tooltip'
    window.moment = moment;
    window._ = _ = lodash;
    _.unique = _.uniq

    Vue.use(VTooltip)
    Vue.component('tabs', Tabs);
    Vue.component('tab', Tab);
    Vue.component('pagination', Pagination);
    Vue.component('o2html', o2html);
    Vue.component('o2row', o2row);
    Vue.component('editable', editable);

    Vue.directive('focus', {
        inserted (el) {
            el.focus()
        }
    })

    export default {
        data () {
            return {
//                WGS: sites.WGS,
                msg: 'Welcome!'
            }
        },
        components: {
//            o2html, o2row, Config, Stats, Ads
        }
    }
</script>

<style>
    .app-title {
        text-align: center;
        margin: 0 auto;
        padding-top: 70px;
    }
    body .window .router-link-exact-active {
        background: #3b99fc;
    }

</style>