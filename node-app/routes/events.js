const express = require('express');
const router = express.Router();
const eventsController = require('../controllers/eventsController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/events', authMiddleware, eventsController.getEvents);
router.post('/events', authMiddleware, eventsController.createEvent);
router.post('/events/register', authMiddleware, eventsController.registerEvent);
router.put('/events/archive', authMiddleware, eventsController.archiveEvent);

router.get('/events/updates', eventsController.sseUpdates);
router.get('/events/:eventId', authMiddleware, eventsController.sseEventAttendees);
router.get('/events/:eventId/user/:userId', authMiddleware, eventsController.getSpecificEvent);

module.exports = router;