const express = require('express');
const router = express.Router();
const eventController = require('../controllers/eventController');
const middleware = require('../../middlewares/middleWare');


router.post('/events', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_EVENTS"), eventController.addEvent);
router.get('/events', middleware.validateAzureJWT, middleware.hasPermission("VIEW_EVENT"), eventController.getEvents);
router.get('/events/past', middleware.validateAzureJWT, middleware.hasPermission("VIEW_EVENT"), eventController.getPastEvents);
router.get('/events/evaluation-questions', middleware.validateAzureJWT, middleware.hasPermission("VIEW_EVENT"), eventController.getAllEvaluationQuestions);

router.get('/event-requirements', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_REQUIREMENTS"),eventController.getEventRequirements);
router.post('/event-requirements/save', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_REQUIREMENTS"), eventController.saveEventRequirements);

router.get('/events/:id', middleware.validateAzureJWT, middleware.hasPermission("VIEW_EVENT"), eventController.getEventById);
router.get('/events/:id/attendees', middleware.validateAzureJWT, middleware.hasPermission("VIEW_EVENT"), eventController.getAttendeesbyEventId);
router.get('/events/:id/stats', middleware.validateAzureJWT, middleware.hasPermission("VIEW_EVENT"), eventController.getEventStats);
router.get('/events/:id/evaluation-responses/grouped', middleware.validateAzureJWT, middleware.hasPermission("VIEW_EVENT"), eventController.getEventEvaluationResponsesByGroup);
router.get('/events/status/:status', middleware.validateAzureJWT, middleware.hasPermission("VIEW_EVENT"), eventController.getEventsByStatus);
router.put('/events/:id', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_EVENTS"), eventController.updateEvent);
router.delete('/events/:id', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_EVENTS"), eventController.deleteEvent);

router.put(
  '/events/:event_id/attendees/:user_id/approve/:approver_email',
  middleware.validateAzureJWT,
  middleware.hasPermission("MANAGE_REGISTRATION"),
  eventController.approvePaidEventRegistration
);

router.put(
  '/events/:event_id/attendees/:user_id/reject/:approver_email',
  middleware.validateAzureJWT,
  middleware.hasPermission("MANAGE_REGISTRATION"),
  eventController.rejectPaidEventRegistration
);

module.exports = router;