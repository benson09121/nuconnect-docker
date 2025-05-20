const express = require('express');
const router = express.Router();
const organizationsController = require('../../web/controllers/organizationsDataController');
const middleware = require('../../middlewares/middleWare');

router.get('/organizations', middleware.validateAzureJWT, middleware.hasPermission("VIEW_ORGANIZATION"), organizationsController.getOrganizations);
router.post('/organizations', middleware.validateAzureJWT, middleware.hasPermission("APPLY_ORGANIZATION"), organizationsController.createOrganizationApplication);
module.exports = router;
