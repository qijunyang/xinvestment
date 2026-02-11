const path = require('path');
const webpack = require('webpack');
const { VueLoaderPlugin } = require('vue-loader');

const createBundleConfig = (name, entry) => ({
  name,
  entry,
  output: {
    path: path.resolve(__dirname, 'src/client/dist'),
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
  createBundleConfig('home', './src/client/home/home.js'),
  // Todos bundle (with devServer config)
  {
    ...createBundleConfig('todos', './src/client/todos/todos.js'),
    devServer: {
      port: 8080,
      hot: true,
      proxy: [
        {
          context: ['/api'],
          target: 'http://localhost:3000',
          changeOrigin: true
        }
      ],
      historyApiFallback: true,
      client: {
        overlay: {
          errors: true,
          warnings: false
        }
      }
    }
  }
];
