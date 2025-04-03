const Redis = require('ioredis');
require('dotenv').config();

const redisClient = new Redis({
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT,
    password: process.env.REDIS_PASS,
    tls: false,
});

const redisSubscriber = new Redis({
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT,
    password: process.env.REDIS_PASS,
    tls: false,
});

redisClient.on('error', (err) => {
    console.error('Redis error:', err);
});

redisClient.on('connect', () => {
    console.log('Connected to Redis');
});

redisSubscriber.on('error', (err) => {
    console.error('Redis subscriber error:', err);
});

redisSubscriber.on('connect', () => {
    console.log('Connected to Redis subscriber');
});

module.exports = { redisClient, redisSubscriber };