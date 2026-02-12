const path = require('path');
const webpack = require('webpack');
const { VueLoaderPlugin } = require('vue-loader');
const CopyWebpackPlugin = require('copy-webpack-plugin');

const createBundleConfig = (name, entry) => ({
  name,
  entry,
  output: {
    path: path.resolve(__dirname, 'public/dist'),
    filename: `${name}.bundle.js`
  },
  module: {
    rules: [
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
        test: /\.css$/,
        use: ['style-loader', 'css-loader']
      }
    ]
  },
  resolve: {
    alias: {
      'vue': 'vue/dist/vue.esm-bundler.js'
    },
    extensions: ['.js', '.vue']
  },
  plugins: [
    new VueLoaderPlugin(),
    new CopyWebpackPlugin({
      patterns: [
        {
          from: path.resolve(__dirname, 'src/client/login/index.html'),
          to: path.resolve(__dirname, 'public/login/index.html')
        },
        {
          from: path.resolve(__dirname, 'src/client/home/index.html'),
          to: path.resolve(__dirname, 'public/home/index.html')
        },
        {
          context: path.resolve(__dirname, 'src/client'),
          from: '**/*.{png,jpg,jpeg,gif,svg,webp,ico,woff,woff2,ttf,otf,eot}',
          to: path.resolve(__dirname, 'public'),
          noErrorOnMissing: true
        }
      ]
    }),
    new webpack.DefinePlugin({
      __VUE_OPTIONS_API__: true,
      __VUE_PROD_DEVTOOLS__: false
    })
  ]
});

module.exports = [
  // Login bundle
  createBundleConfig('login', './src/client/login/login.js'),
  // Home bundle
  createBundleConfig('home', './src/client/home/home.js')
];
