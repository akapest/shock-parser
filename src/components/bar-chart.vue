
<script>
    import VueCharts from 'vue-chartjs'
    import { Bar } from 'vue-chartjs'
    import Promise from 'bluebird'
    import _ from 'lodash'


    export default {
        extends: Bar,
        props: ['chartData'],
        mixins: [VueCharts.mixins.reactiveProp],
        methods: {

            render(){
                this.renderChart(this.chartData,
                    {options: {
                        scales: {
                            xAxes: [{
                                stacked: true
                            }],
                            yAxes: [{
                                ticks: {
                                    beginAtZero:true
                                },
                                stacked: true

                            }]
                        }
                    }}
                )
            },
        },

        mounted () {
            this.render()
        }
    }
</script>

<style>

</style>