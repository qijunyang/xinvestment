const axios = require('axios');
const { logger } = require('../log/logger');

// Abort example:
// const controller = new AbortController();
// const client = new HttpClient();
// const req = client.get('/api/foo', { signal: controller.signal });
// controller.abort();

class HttpClient {
  constructor(options = {}) {
    const {
      baseURL = process.env.HTTP_BASE_URL || '',
      timeout = 10000,
      headers = {}
    } = options;

    this.client = axios.create({
      baseURL,
      timeout,
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        ...headers
      }
    });

    this.client.interceptors.request.use((config) => {
      const method = (config.method || 'GET').toUpperCase();
      const url = config.baseURL ? `${config.baseURL}${config.url}` : config.url;
      config.metadata = { startTime: Date.now() };
      logger.info(`Outbound request received: ${method} ${url}`);
      return config;
    });

    this.client.interceptors.response.use(
      (response) => {
        const method = (response.config.method || 'GET').toUpperCase();
        const url = response.config.baseURL ? `${response.config.baseURL}${response.config.url}` : response.config.url;
        const durationMs = response.config.metadata ? Date.now() - response.config.metadata.startTime : undefined;
        const durationText = typeof durationMs === 'number' ? ` duration=${durationMs}ms` : '';
        logger.info(`Outbound response received: ${method} ${url} -> ${response.status}${durationText}`);
        return response;
      },
      (error) => {
        const config = error.config || {};
        const method = (config.method || 'GET').toUpperCase();
        const url = config.baseURL ? `${config.baseURL}${config.url}` : config.url;
        const durationMs = config.metadata ? Date.now() - config.metadata.startTime : undefined;
        const durationText = typeof durationMs === 'number' ? ` duration=${durationMs}ms` : '';
        logger.warn(`Outbound response received: ${method} ${url} -> ERROR${durationText}`);
        return Promise.reject(error);
      }
    );
  }

  request(config) {
    return this.client.request(config);
  }

  get(url, config = {}) {
    return this.client.get(url, config);
  }

  post(url, data, config = {}) {
    return this.client.post(url, data, config);
  }

  put(url, data, config = {}) {
    return this.client.put(url, data, config);
  }

  patch(url, data, config = {}) {
    return this.client.patch(url, data, config);
  }

  delete(url, config = {}) {
    return this.client.delete(url, config);
  }
}

module.exports = HttpClient;
