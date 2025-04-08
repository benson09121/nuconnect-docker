const express = require('express');
const router = express.Router();
const eventsController = require('../controllers/eventsController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/events', authMiddleware, eventsController.getEvents);
router.get('/events/upcoming', authMiddleware, eventsController.getUpcomingEvents);
router.get('/events/tickets', authMiddleware, eventsController.getTickets);
router.get('/events/:eventId', authMiddleware, eventsController.sseEventAttendees);
router.get('/events/:eventId/user/:userId', authMiddleware, eventsController.getSpecificEvent);
router.post('/events', authMiddleware, eventsController.createEvent);
router.post('/events/register', authMiddleware, eventsController.registerEvent);
router.post('/events/addcertificate', authMiddleware, eventsController.addCertificate)
router.put('/events/archive', authMiddleware, eventsController.archiveEvent);
router.get('/organizations', authMiddleware, eventsController.getOrganizations);
router.get('/profile/organization', authMiddleware, eventsController.getUserOrganization);
// Ensure all referenced methods exist in eventsController

module.exports = router;