var path = require('path')
var webpack = require('webpack')

module.exports = {
    entry: {
		main: "./src/app.js",
	},
	output: {
		path: path.join(__dirname, "dist"),
        publicPath: 'dist/',
		filename: "[name].bundle.js",
		chunkFilename: "[id].chunk.js"
	},
    resolve: {
        alias: {
            vue: 'vue/dist/vue.js'
        }
    },
    plugins: [
        new webpack.DllReferencePlugin({
            context: '.',
            manifest: require('./dist/vendor-manifest.json'),
        }),
    ],
    target: 'electron-renderer',
    module: {
        loaders: [
            {
                test: /\.vue$/,
                loader: 'vue-loader'
            },
            {
                test: /\.js$/,
                loader: 'babel-loader',
                exclude: /node_modules/
            },
            {
                test: /\.(png|jpg|gif|svg)$/,
                loader: 'file',
                query: {
                    name: '[name].[ext]?[hash]'
                }
            },
            {
                test: /\.coffee$/,
                exclude: [/node_modules/, '/specs/'],
                use: [ 'coffee-loader' ]
            },
            {
                test: /\.scss$/,
                use: [{
                    loader: "style-loader"
                }, {
                    loader: "css-loader"
                }, {
                    loader: "sass-loader",
                    options: {
                        includePaths: ["src/styles.scss"]
                    }
                }]
            },
            {
                test: /\.node$/,
                loader: "node-loader"
            }
        ],
    },
}

if (process.env.NODE_ENV === 'production') {
    // plugins.push(
    //     new webpack.DefinePlugin({
    //         'process.env': {
    //             NODE_ENV: '"production"'
    //         }
    //     })
    // );
    // plugins.push(new webpack.optimize.UglifyJsPlugin({
    //     compress: {
    //         warnings: false
    //     }
    // }))
        // new webpack.optimize.CommonsChunkPlugin({
        //     name: 'vendor',
        //     minChunks: function (module) {
        //         return module.context && module.context.indexOf('node_modules') !== -1;
        //     }
        // }),

} else {
    module.exports.devtool = '#source-map'
}