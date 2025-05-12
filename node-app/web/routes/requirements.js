const express = require('express');
const router = express.Router();
const requirementController = require('../../web/controllers/requirementController');
const middleware = require('../../middlewares/middleWare');

router.post('/requirements', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_REQUIREMENTS"), requirementController.addRequirement);
router.get('/requirements', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_REQUIREMENTS"), requirementController.getRequirements);
router.get('/requirements/template', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_REQUIREMENTS"), requirementController.downloadTemplate);
router.delete('/requirements/', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_REQUIREMENTS"), requirementController.deleteRequirement);

module.exports = router;
