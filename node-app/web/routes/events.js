const express = require('express');
const router = express.Router();
const eventController = require('../controllers/eventController');
const middleware = require('../../middlewares/middleWare');


router.post('/events', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_EVENTS"), eventController.addEvent);
router.get('/events', middleware.validateAzureJWT, middleware.hasPermission("VIEW_EVENT"), eventController.getEvents);
router.get('/events/past', middleware.validateAzureJWT, middleware.hasPermission("VIEW_EVENT"), eventController.getPastEvents);


router.get('/events/:id', middleware.validateAzureJWT, middleware.hasPermission("VIEW_EVENT"), eventController.getEventById);
router.get('/events/:id/attendees', middleware.validateAzureJWT, middleware.hasPermission("VIEW_EVENT"), eventController.getAttendeesbyEventId);
router.get('/events/status/:status', middleware.validateAzureJWT, middleware.hasPermission("VIEW_EVENT"), eventController.getEventsByStatus);
router.put('/events/:id', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_EVENTS"), eventController.updateEvent);
router.delete('/events/:id', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_EVENTS"), eventController.deleteEvent);

module.exports = router;