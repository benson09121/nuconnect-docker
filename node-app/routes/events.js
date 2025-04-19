const express = require('express');
const router = express.Router();
const eventsController = require('../controllers/eventsController');
const authMiddleware = require('../middlewares/authMiddleware');


router.get('/events', authMiddleware, eventsController.getEvents);
router.get('/events/upcoming', authMiddleware, eventsController.getUpcomingEvents);
router.get('/events/tickets', authMiddleware, eventsController.getTickets);
router.get('/events/:eventId', authMiddleware, eventsController.sseEventAttendees);
router.get('/events/:eventId/user/:userId', authMiddleware, eventsController.getSpecificEvent);
router.get('/events/evaluation/:eventId', authMiddleware, eventsController.getEvaluation);
router.post('/events/evaluation/submit', authMiddleware, eventsController.submitEvaluation);
router.post('/events', authMiddleware, eventsController.createEvent);
router.post('/events/register', authMiddleware, eventsController.registerEvent);
router.post('/events/addcertificate', authMiddleware, eventsController.addCertificate);
router.post('/events/generatecertificate', authMiddleware, eventsController.addGeneratedCertificate);
router.put('/events/archive', authMiddleware, eventsController.archiveEvent);
// Ensure all referenced methods exist in eventsController

module.exports = router;