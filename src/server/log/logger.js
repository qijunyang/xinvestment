const log4js = require('log4js');

log4js.configure({
  appenders: {
    out: {
      type: 'stdout',
      layout: {
        type: 'pattern',
        pattern: '%d %p %c %f:%l [req:%X{requestId} user:%X{userId}] - %m',
        enableCallStack: true
      }
    },
    httpOut: {
      type: 'stdout',
      layout: {
        type: 'pattern',
        pattern: '%d %p %c - %m'
      }
    }
  },
  categories: {
    default: { appenders: ['out'], level: 'info' },
    http: { appenders: ['httpOut'], level: 'info' }
  }
});

const logger = log4js.getLogger('app');
const httpAccessLogger = log4js.getLogger('http');
const httpLogger = log4js.connectLogger(httpAccessLogger, {
  level: 'info',
  nolog: /.*\.(css|js|map|png|jpg|jpeg|gif|svg|webp|ico|woff|woff2|ttf|otf|eot)$/,
  format: (req) => {
    const requestId = req.requestId || req.get('x-request-id') || '-';
    const userId = req.user?.userId || '-';
    return `[req:${requestId} user:${userId}] - "${req.originalUrl}"`;
  }
});

const setRequestContext = ({ requestId, userId }) => {
  logger.addContext('requestId', requestId || '-');
  logger.addContext('userId', userId || '-');
  httpAccessLogger.addContext('requestId', requestId || '-');
  httpAccessLogger.addContext('userId', userId || '-');
};

const clearRequestContext = () => {
  logger.clearContext('requestId');
  logger.clearContext('userId');
  httpAccessLogger.clearContext('requestId');
  httpAccessLogger.clearContext('userId');
};

module.exports = {
  logger,
  httpLogger,
  setRequestContext,
  clearRequestContext
};
