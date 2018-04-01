var path = require('path')
var webpack = require('webpack')

module.exports = {
    entry: {
        vendor: [
            'assert',
            'bluebird',
            'cheerio',
            'chart.js',
            'fs',
            'debug',
            'lodash',
            'querystring',
            'request',
            'rollbar',
            'moment',
            'mongoose',
            'vue',
            "vue-pagination-2",
            'vue-template-compiler',
            "vue-tabs-component",
            'vue-router',
            'winston',
            'winston-logrotate',
            'proxy-lists'
        ],
    },
    target: 'electron-renderer',
    output: {
        filename: '[name].bundle.js',
        path: path.join(__dirname, "dist"),
        library: '[name]_lib',
    },
    resolve: {
        alias: {
            vue: 'vue/dist/vue.js'
        }
    },
    module: {
        loaders: [
            {
                test: /\.node$/,
                loader: "node-loader"
            }
        ],
    },

    plugins: [
        new webpack.DllPlugin({
            path: 'dist/[name]-manifest.json',
            name: '[name]_lib'
        }),
    ],
}

