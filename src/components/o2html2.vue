<template>
    <div>
        <div v-for="(value, key, index) in object">
          {{ labels[key] }}: {{ value }}
        </div>
    </div>

</template>

<script>
    export default {
        props: ['object', 'labels']
    }
</script>

<style>
</style>