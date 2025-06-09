const express = require('express');
const router = express.Router();
const middleware = require('../../middlewares/middleWare');
const sseController = require('../controllers/sseController');
// Track active subscriptions per session


router.get('/sse', middleware.validateAzureJWT, sseController.handleSSEConnection);

module.exports = router;