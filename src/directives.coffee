Vue = require 'vue'

Vue.directive 'click-outside',
  bind: (el, binding, vnode) ->
    el.event = (event) ->
      if (!(el == event.target || el.contains(event.target)))
        vnode.context[binding.expression](event)
    document.body.addEventListener('click', el.event)

  unbind: (el) ->
    document.body.removeEventListener('click', el.event)


Vue.component 'editable-list',
#    props: ['fields']
    template: '''<div>
                    <editable v-for="f in [{value: 'any'}, {value: 'some'}]" v-bind:field="f" v-on:change="change"></editable>
                </div>'''
    methods:
        change: (field) ->
            console.log field