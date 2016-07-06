const APP_ENV = process.env.APP_ENV || 'development';
const webpack = require('webpack');
const path = require('path');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const ExtractTextPlugin = require('extract-text-webpack-plugin');
const OptimizeCssAssetsPlugin = require('optimize-css-assets-webpack-plugin');

var jsConfig = {
  name: 'js',
  entry: {
    bundle: path.resolve(__dirname, 'src', 'js', 'main.coffee'),
    terminal: path.resolve(__dirname, 'src', 'js', 'terminal', 'terminal.coffee')
  },
  output: {
    path: path.resolve(__dirname, 'dist', 'assets'),
    publicPath: "/assets/",
    filename: '[name].js'
  },
  module: {
    loaders: [
      { test: /\.coffee$/, loader: 'coffee' },
      { test: /\.emblem$/, loader: 'ember-emblem-loader' }
    ]
  },
  resolve: {
    extensions: ['', '.js', '.coffee', '.emblem'],
  },
  plugins: [
    new CopyWebpackPlugin([{
      from: path.resolve(__dirname, 'src', 'index.html'),
      to: path.resolve(__dirname, 'dist', 'index.html')
    }])
  ],
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
};

if (APP_ENV !== 'development') {
  jsConfig.plugins.push(new webpack.optimize.UglifyJsPlugin({compress:{warnings: false}}));
}

var cssConfig = {
  name: 'css',
  entry: {
    app: path.resolve(__dirname, 'src', 'css', 'application.sass'),
    terminal: path.resolve(__dirname, 'src', 'css', 'terminal.sass')
  },
  output: {
    path: path.resolve(__dirname, 'dist', 'assets'),
    publicPath: "/assets/",
    filename: '[name].css'
  },
  module: {
    loaders: [
      { test: /\.s(a|c)ss$/, loader: ExtractTextPlugin.extract('style', 'css!sass') },
      { test: /\.(woff|woff2|eot|ttf|svg)(\?.*$|$)/, loader: 'file' }
    ]
  },
  resolve: {
    extensions: ['', 'css', 'sass'],
  },
  plugins: [
    new ExtractTextPlugin('[name].css', {
      allChunks: true
    }),
    new OptimizeCssAssetsPlugin()
  ],
  node: {
    fs: 'empty'
  },
  debug: true,
  devtool: 'source-map'
};

module.exports = [jsConfig, cssConfig]
