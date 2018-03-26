
<script>
    import VueCharts from 'vue-chartjs'
    import {Pie} from 'vue-chartjs'

    export default {
        extends: Pie,
        mounted () {
            // Overwriting base render method with actual data.
            this.renderChart({
                labels: ['WGG', 'WGS'],
                datasets: [
                    {
                        backgroundColor: ['#f87979', '#eee'],
                        data: [40, 20]
                    }
                ]
            })
        }
    }
</script>

<style>
</style>