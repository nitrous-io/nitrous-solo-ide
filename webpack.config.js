const webpack = require('webpack')
const path = require('path')

module.exports = {
  entry: [
    path.resolve(__dirname, 'src', 'js', 'main.coffee')
  ],
  //entry: {
    //app: path.resolve(__dirname, 'src', 'main.coffee'),
    //vendor: [path.resolve(__dirname, 'vendor', 'handlebars.min.js'), path.resolve(__dirname, 'vendor', 'ember.min.js')],
    //bundle: [path.resolve(__dirname, 'vendor', 'handlebars.js'), path.resolve(__dirname, 'vendor', 'ember.min.js'), path.resolve(__dirname, 'src', 'main.coffee')]
    //bundle: [path.resolve(__dirname, 'vendor', 'ember.js'), path.resolve(__dirname, 'src', 'main.coffee')]
    //bundle: [path.resolve(__dirname, 'src', 'main.coffee')]
  //},
  output: {
    path: path.resolve(__dirname, 'dist', 'js'),
    filename: 'bundle.js'
  },
  module: {
    loaders: [
      { test: /\.coffee$/, loader: "coffee" },
      { test: /\.emblem$/, loader: "ember-emblem-loader" }
    ]
  },
  resolve: {
    extensions: ['', '.js', '.coffee', '.emblem'],
  },
  //plugins: [
    //new webpack.optimize.UglifyJsPlugin({
      //compress: {
        //warnings: false
      //}
    //})
  //],
  node: {
    fs: "empty"
  },
  debug: true,
  devtool: 'source-map',
  devServer: {
    host: '127.0.0.1',
    port: 3838,
    contentBase: './dist'
  }
}
