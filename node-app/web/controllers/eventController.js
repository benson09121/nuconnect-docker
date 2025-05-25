const eventModel = require('../models/eventModel');

async function addEvent(req, res) {
    try {
        const event = req.body;
        // Optionally, validate required fields here
        const result = await eventModel.addEvent(event);
        res.status(201).json({ message: 'Event created successfully', event_id: result.insertId });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while creating the event.",
        });
    }
}

async function getEvents(req, res) {
    try {
        const events = await eventModel.getEvents();
        res.status(200).json(events);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching events.",
        });
    }
}

async function getEventById(req, res) {
    try {
        const event_id = req.params.id;
        const event = await eventModel.getEventById(event_id);
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }
        res.status(200).json(event);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the event.",
        });
    }
}

async function getAttendeesbyEventId(req, res) {
    try {
        const event_id = req.params.id;
        const attendees = await eventModel.getAttendeesByEventId(event_id);
        if (attendees.length === 0) {
            return res.status(404).json({ message: 'No attendees found for this event' });
        }
        res.status(200).json(attendees);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching attendees for the event.",
        });
    }
}

async function getEventsByStatus(req, res) {
    try {
        const status = req.params.status;
        const events = await eventModel.getEventsByStatus(status);
        if (events.length === 0) {
            return res.status(404).json({ message: 'No events found with the specified status' });
        }
        res.status(200).json(events);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching events by status.",
        });
    }
}

async function getPastEvents(req, res) {
    try {
        const events = await eventModel.getPastEvents();
        console.log('Past events from DB:', events); // Add this log
        res.status(200).json(events || []); // Ensure array is always returned
    } catch (error) {
        console.error('Error in getPastEvents:', error);
        res.status(500).json({
            error: error.message,
            details: process.env.NODE_ENV === 'development' ? error.stack : undefined
        });
    }
}

async function updateEvent(req, res) {
    try {
        const event_id = req.params.id;
        const event = req.body;
        const result = await eventModel.updateEvent(event_id, event);
        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Event not found' });
        }
        res.status(200).json({ message: 'Event updated successfully' });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while updating the event.",
        });
    }
}

async function deleteEvent(req, res) {
    try {
        const event_id = req.params.id;
        const result = await eventModel.deleteEvent(event_id);
        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Event not found' });
        }
        res.status(200).json({ message: 'Event deleted successfully' });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while deleting the event.",
        });
    }
}

module.exports = {
    addEvent,
    getEvents,
    getEventById,
    getPastEvents,
    getAttendeesbyEventId,
    updateEvent,
    deleteEvent,
    getEventsByStatus,
};