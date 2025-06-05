const express = require('express');
const router = express.Router();
const redisClient = require('../../config/redis');

// Create Redis subscriber
const redis = new Redis(); // default: localhost:6379

// SSE endpoint
router.get('/events', (req, res) => {
    // Set headers for SSE
    res.set({
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive'
    });
    res.flushHeaders();

    // Send a comment to keep the connection alive
    const keepAlive = setInterval(() => {
        res.write(': keep-alive\n\n');
    }, 20000);

    // Handler for Redis messages
    const onMessage = (channel, message) => {
        res.write(`event: message\n`);
        res.write(`data: ${message}\n\n`);
    };

    // Subscribe to a Redis channel
    redis.subscribe('notifications', (err, count) => {
        if (err) {
            res.write(`event: error\ndata: Redis subscribe error\n\n`);
        }
    });

    redis.on('message', onMessage);

    // Clean up on client disconnect
    req.on('close', () => {
        clearInterval(keepAlive);
        redis.removeListener('message', onMessage);
        res.end();
    });
});

// Example endpoint to publish a message (for testing)
router.post('/notify', express.json(), (req, res) => {
    const message = req.body.message || 'Hello from Redis!';
    redis.publish('notifications', message);
    res.json({ status: 'sent', message });
});

module.exports = router;