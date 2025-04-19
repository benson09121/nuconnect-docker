const eventModel = require('../models/eventModel');
const { redisClient, redisSubscriber } = require('../config/redis');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
// const { scanner, virusCheck } = require('../config/clamav');
const { Auth } = require("../models/userIdModel");
const TemplateHandler = require('easy-template-x').TemplateHandler;
const convertDocxToPdf = require('../config/convertToPdf');

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

async function getUpcomingEvents(req, res) {
    try {
        const upcomingEvents = await eventModel.getUpcomingEvents();
        res.json(upcomingEvents);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}
async function addCertificate(req, res) {
    try {
        console.log('addCertificate: Request received'); // Log entry point
        const { event_id } = req.body;
        console.log('addCertificate: event_id:', event_id); // Log event_id

        if (!req.files || !req.files.file) {
            console.error('addCertificate: No file uploaded');
            return res.status(400).json({ message: 'No file uploaded' });
        }

        const uploadedFile = req.files.file;
        console.log('addCertificate: Uploaded file details:', uploadedFile); // Log file details

        const fileBuffer = uploadedFile.data;
        console.log('addCertificate: File buffer size:', fileBuffer.length); // Log file buffer size

        // Validate file type
        if (!uploadedFile.mimetype.includes('application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/octet-stream')) {
            console.error('addCertificate: Invalid file type:', uploadedFile.mimetype);
            return res.status(400).json({ message: 'Only .docx files allowed' });
        }

        // Virus scan
        // console.log('addCertificate: Starting virus scan');
        // const isClean = await virusCheck(fileBuffer);
        // if (!isClean) {
        //     console.error('addCertificate: File contains malware');
        //     return res.status(400).json({ error: 'File contains malware' });
        // }
        // console.log('addCertificate: Virus scan completed');

        // Save template

        
        const filename = `event-${event_id}-template.docx`;
        const templatePath = path.join('/app/certificates/templates', filename);
        console.log('addCertificate: Saving file to path:', templatePath);

        try {
            fs.writeFileSync(templatePath, uploadedFile.data);
            console.log('addCertificate: File saved successfully');
        } catch (writeError) {
            console.error('addCertificate: Error saving file:', writeError);
            return res.status(500).json({ message: 'Error saving file', error: writeError.message });
        }

        // Database insert
        console.log('addCertificate: Inserting template path into database');
        await eventModel.AddCertificateTemplate(event_id, templatePath);
        console.log('addCertificate: Database insert successful');

        res.status(201).json({ path: templatePath });
    } catch (error) {
        console.error('addCertificate: Unexpected error:', error); // Log unexpected errors
        res.status(500).json({ message: 'An unexpected error occurred', error: error.message });
    }
}

async function addGeneratedCertificate(req) {
    try {
        const { event_id } = req.body;
        const verification_code = uuidv4();

        // Get certificate template
        const template = await eventModel.getCertificateTemplate(event_id);
        if (!template || !template[0]) throw new Error('No template found for this event');
        const templatePath = template[0].template_path;

        // Validate and process DOCX template
        const templateContent = fs.readFileSync(templatePath);
        if (!templateContent || templateContent.length === 0) {
            throw new Error('Template file is empty or corrupted');
        }

        const data = {
            name: `${Auth.get_first_name} ${Auth.get_last_name}`,
        };

        // Generate filenames
        const safeFirstName = Auth.get_first_name.replace(/[^a-z0-9]/gi, '_').toLowerCase();
        const safeLastName = Auth.get_last_name.replace(/[^a-z0-9]/gi, '_').toLowerCase();
        const baseFilename = `Certificate_${safeFirstName}_${safeLastName}`;
        const docxPath = path.join("/app/certificates/templates", `${baseFilename}_${verification_code}.docx`);
        const pdfFilename = `${baseFilename}_${verification_code}.pdf`;
        const pdfPath = `/app/certificates/generated/${pdfFilename}`;

        // Save temporary DOCX
        const handler = new TemplateHandler(templateContent);
        const doc = await handler.process(templateContent, data);
        fs.writeFileSync(docxPath, doc);

        await convertDocxToPdf(docxPath, pdfPath);
        fs.unlinkSync(docxPath);

        // Database insert
        const template_id = template[0].template_id;
        await eventModel.addGeneratedCertificate({
            event_id,
            template_id,
            pdfPath,
            verification_code,
        });

        return { message: 'Certificate generated successfully', path: pdfPath };
    } catch (error) {
        console.error('addGeneratedCertificate: Error:', error.message);
        throw error; // Throw the error to be handled by the caller
    }
}

async function getEvaluation(req,res) {
    try {
        const event_id = parseInt(req.params.eventId, 10);
        const evaluation = await eventModel.getEvaluation(event_id);
        if (!evaluation) {
            return res.status(404).json({ message: 'Evaluation not found' });
        }
        res.json(evaluation);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
  }
  
async function submitEvaluation(req, res) {
    try {
        const response = req.body;
        const event_id = req.body.event_id;
        console.log(response);

        await eventModel.submitEvaluation(response);

        // Call addGeneratedCertificate and handle its result
        const certificateResult = await addGeneratedCertificate({ body: { event_id } });
        console.log(certificateResult);

        res.status(201).json({ message: 'Evaluation submitted successfully', certificate: certificateResult });
    } catch (error) {
        console.error('submitEvaluation: Error:', error.message);
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
    sseEventAttendees,
    getUpcomingEvents,
    addCertificate,
    addGeneratedCertificate,
    getEvaluation,
    submitEvaluation,
};
