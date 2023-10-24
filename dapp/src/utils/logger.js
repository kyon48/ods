const pino = require('pino');

const logger = pino({
    transport: {
        target: 'pino-pretty',
        colorize: true,
        levelFirst: true,
        translateTime: true
    },
    name: 'Islab',
    level: process.env.FABRIC_CLIENT_LOG_LEVEL
});

module.exports.logger = logger;