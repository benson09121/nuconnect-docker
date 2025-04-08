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
        const { user_id, title, description, venue, date, start_time, end_time, organization_id, status, type, is_open_to_all } = req.body;
        const orgId = parseInt(organization_id, 10);
        const newEvent = await eventModel.createEvent(user_id, title, description, venue, date, start_time, end_time, orgId, status, type, is_open_to_all);

        // No cache updates or notifications here since the event is pending approval
        res.status(201).json(newEvent);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

async function registerEvent(req, res) {
    try {
        const event_id = parseInt(req.body.event_id, 10);
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
        if (attendees) {
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

// // SSE endpoint for real-time updates
// function sseUpdates(req, res) {
//     const userId = req.userId; // Extract user_id from the authenticated request

//     res.setHeader('Content-Type', 'text/event-stream');
//     res.setHeader('Cache-Control', 'no-cache');
//     res.setHeader('Connection', 'keep-alive');

//     const onMessage = (channel, message) => {
//         if (channel === `events:user:${userId}`) {
//             res.write(`data: ${message}\n\n`);
//         }
//     };

//     redisSubscriber.on('message', onMessage);
//     redisSubscriber.subscribe(`events:user:${userId}`);

//     req.on('close', () => {
//         redisSubscriber.unsubscribe(`events:user:${userId}`);
//         redisSubscriber.removeListener('message', onMessage);
//         res.end();
//     });
// }

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

async function getTickets(req, res) {
    try {
        const getTicket = await eventModel.getTickets();
        res.json(getTicket);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }

}

async function getOrganizations(req, res) {
    try {
        const organizations = await eventModel.getOrganizations();
        res.json(organizations);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}
async function getUpcomingEvents(req, res) {
    try {
        const upcomingEvents = await eventModel.getUpcomingEvents();
        res.json(upcomingEvents);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}
async function getUserOrganization(req, res) {
    try {
        const userOrganization = await eventModel.getUserOrganization();
        res.json(userOrganization);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}
async function addCertificate(req, res) {
    try {
        const { event_id, filepath, pdf } = req.body;
        const result = await eventModel.AddCertificate(event_id, filepath);
        res.json(result);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

module.exports = {
    getEvents,
    createEvent,
    registerEvent,
    archiveEvent,
    getSpecificEvent,
    getTickets,
    getOrganizations,
    sseEventAttendees,
    getUpcomingEvents,
    getUserOrganization,
};
