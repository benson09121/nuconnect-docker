const express = require('express');
const router = express.Router();
const eventsController = require('../controllers/eventsController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/events', authMiddleware, eventsController.getEvents);
router.get('/events/updates', authMiddleware, eventsController.getUpdates);
router.post('/events', authMiddleware, eventsController.createEvent);
router.post('/events/register', authMiddleware, eventsController.registerEvent);
module.exports = router;
