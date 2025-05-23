const express = require('express');
const router = express.Router();
const logController = require('../controllers/logController');
const middleware = require('../../middlewares/middleWare');

router.get('/logs', middleware.validateAzureJWT, middleware.hasPermission("VIEW_LOGS"), logController.getLogs);

module.exports = router;
