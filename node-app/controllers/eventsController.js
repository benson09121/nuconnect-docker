const eventModel = require('../models/eventModel');
const { redisClient, redisSubscriber } = require('../config/redis');

async function getEvents(req, res) {
    try {
        const events = await eventModel.getAllEvents();
        res.json(events);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

async function createEvent(req, res) {
    try {
        const { user_id, title, description, venue, date, start_time, end_time, organization_id, department_id, type, status } = req.body;
        const newEvent = await eventModel.createEvent(user_id, title, description, venue, date, start_time, end_time, organization_id, department_id, type, status);

        // Publish the new event to Redis
        redisClient.publish('events', JSON.stringify({ type: 'create', event: newEvent }));

        // Refresh the cache
        await eventModel.refreshCache();

        res.status(201).json(newEvent);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

async function registerEvent(req, res) {
    try {
        const event_id = parseInt(req.body.event_id,10);
        const checkRegister = await eventModel.checkEventRegistration(event_id);
        if (checkRegister) {
            return res.status(400).json({ message: 'Already registered for this event' });
        }
        const newAttendee = await eventModel.registerEvent(event_id);
        if (!newAttendee) {
            return res.status(404).json({ message: 'Event not found' });
        }
        redisClient.publish(`events:attendees:${event_id}`, JSON.stringify({ type: 'Register', attendee: newAttendee }));

        // Refresh the cache
        await eventModel.refreshAttendeesCache(event_id);

        res.status(201).json(newAttendee);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

async function archiveEvent(req, res) {
    try {
        const { event_id } = req.body;
        await eventModel.archiveEvent(event_id);

        redisClient.publish('events', JSON.stringify({ type: 'archive', event_id }));

        await eventModel.refreshCache();
        res.status(200).json({ message: 'Event Archived' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

async function getSpecificEvent(req, res) {
    try {
        const eventId = parseInt(req.params.eventId, 10);
        const userId = req.params.userId;
        const event = await eventModel.getSpecificEvent(eventId, userId);
        let attendees = await eventModel.getEventAttendees(eventId);
        if (attendees){
            attendees = attendees[0][0];
        }
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }


        const response = {
            event: event,
            attendees: attendees
        };
        res.json(response);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

// SSE endpoint for real-time updates
function sseUpdates(req, res) {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    const onMessage = (channel, message) => {
        if (channel === 'events') {
            res.write(`data: ${message}\n\n`);
        }
    };

    redisSubscriber.on('message', onMessage);
    redisSubscriber.subscribe('events');

    req.on('close', () => {
        redisSubscriber.unsubscribe('events');
        redisSubscriber.removeListener('message', onMessage);
        res.end();
    });
}

async function sseEventAttendees(req, res) {
    const eventId = parseInt(req.params.eventId, 10);

    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    const onMessage = (channel, message) => {
        if (channel === `events:attendees:${eventId}`) {
            res.write(`data: ${message}\n\n`);
        }
    };

    redisSubscriber.on('message', onMessage);
    redisSubscriber.subscribe(`events:attendees:${eventId}`);

    req.on('close', () => {
        redisSubscriber.unsubscribe(`events:attendees:${eventId}`);
        redisSubscriber.removeListener('message', onMessage);
        res.end();
    });
}

module.exports = {
    getEvents,
    createEvent,
    registerEvent,
    archiveEvent,
    getSpecificEvent,
    sseUpdates,
    sseEventAttendees
};
