const express = require('express');
const router = express.Router();
const organizationsController = require('../../web/controllers/organizationsDataController');
const middleware = require('../../middlewares/middleWare');

router.get('/organizations', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_REQUIREMENTS"), requirementController.getRequirements);
module.exports = router;
