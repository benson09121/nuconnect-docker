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

async function approvePaidEventRegistration(req, res) {
  try {
    const { event_id, user_id, approver_email } = req.params;
    const { remarks } = req.body; // remarks is optional

    if (!approver_email) {
      return res.status(400).json({ message: "Approver email is required." });
    }

    // Lookup user_id from email
    const approver = await eventModel.getUserByEmail(approver_email);
    if (!approver) {
      return res.status(404).json({ message: "Approver not found." });
    }

    const result = await eventModel.approvePaidEventRegistration(
      event_id,
      user_id,
      approver.user_id,
      remarks 
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Registration not found or already approved' });
    }

    res.status(200).json({ message: 'Registration approved successfully' });
  } catch (error) {
    res.status(500).json({
      error: error.message || "An error occurred while approving the registration.",
    });
  }
}

async function rejectPaidEventRegistration(req, res) {
  try {
    const { event_id, user_id, approver_email } = req.params;
    const { remarks } = req.body;

    if (!approver_email) {
      return res.status(400).json({ message: "Approver email is required." });
    }
    if (!remarks) {
      return res.status(400).json({ message: "Remarks are required." });
    }

    // Lookup user_id from email
    const approver = await eventModel.getUserByEmail(approver_email);
    if (!approver) {
      return res.status(404).json({ message: "Approver not found." });
    }

    const result = await eventModel.rejectPaidEventRegistration(
      event_id,
      user_id,
      approver.user_id, // pass the user_id to the stored procedure
      remarks
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Registration not found or already rejected' });
    }

    res.status(200).json({ message: 'Registration rejected successfully' });
  } catch (error) {
    res.status(500).json({
      error: error.message || "An error occurred while rejecting the registration.",
    });
  }
}

async function getEventStats(req, res) {
  try {
    const event_id = req.params.id;
    const stats = await eventModel.getEventStats(event_id);
    res.status(200).json(stats);
  } catch (error) {
    res.status(500).json({ error: error.message });
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
    approvePaidEventRegistration,
    rejectPaidEventRegistration,
    getEventStats
};