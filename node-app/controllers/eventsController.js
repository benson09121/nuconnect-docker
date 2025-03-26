const eventsModel = require('../models/eventsModel');
const { redisClient, redisSubscriber, clients } = require('../config/redis');

async function getEvents(req, res) {
    try {
        const events = await eventsModel.getAllEvents();
        res.json(events);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

function getUpdates(req, res) {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    clients.push(res);

    req.on('close', () => {
        clients.splice(clients.indexOf(res), 1);
    });
}

async function createEvent(req, res) {
    try {
        const { user_id, title, description, venue, date, start_time, end_time } = req.body;
        const newEvent = await eventsModel.createEvent(user_id, title, description, venue, date, start_time, end_time);
        redisClient.publish('events', JSON.stringify(newEvent));
        res.status(201).json(newEvent);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

async function registerEvent(req, res) {
    try {
        const { event_id} = req.body;
        await eventsModel.registerEvent(event_id);
        res.status(200).json({ message: 'Event Registered' });

    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}


redisSubscriber.subscribe('events', (err, count) => {
    if (err) {
        console.error('Redis subscribe error:', err);
        return;
    }
    console.log(`Subscribed to ${count} channels.`);
});

redisSubscriber.on('message', (channel, message) => {
    if (channel === 'events') {
        clients.forEach(client => client.write(`data: ${message}\n\n`));
    }
});

module.exports = { getEvents, getUpdates, createEvent, registerEvent };
