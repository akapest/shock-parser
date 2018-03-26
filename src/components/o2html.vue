<template>
    <div>
        <div v-for="(value, key, index) in object">
          {{ key }}: {{ value }}
        </div>
    </div>

</template>

<script>
    export default {
        props: ['object']
    }
</script>

<style>
</style>