
<script>
    import _ from 'lodash'
    import r from './o2row-render.coffee'

    export default {
        props: ['object', 'site'],
//        data () {
//            return {object: {}, site: {}}
//        },
        render (h) {
            return r(h, this.object, this.site)
        }
    }
</script>

<style>
</style>