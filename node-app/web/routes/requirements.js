const express = require('express');
const router = express.Router();
const requirementController = require('../../web/controllers/requirementController');
const middleware = require('../../middlewares/middleWare');

router.post('/requirements', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_REQUIREMENTS"), requirementController.addRequirement);
router.get('/requirements', middleware.validateAzureJWT, middleware.hasPermission(["MANAGE_REQUIREMENTS", "APPLY_ORGANIZATION"]), requirementController.getRequirements);
router.get('/requirements/template', middleware.validateAzureJWT, middleware.hasPermission(["MANAGE_REQUIREMENTS", "APPLY_ORGANIZATION"]), requirementController.downloadTemplate);
router.delete('/requirements/', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_REQUIREMENTS"), requirementController.deleteRequirement);
router.put('/requirements', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_REQUIREMENTS"), requirementController.updateRequirement);
router.post('/requirement-period', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_REQUIREMENTS"), requirementController.addApplicationPeriod);
router.get('/requirement-active-period', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_REQUIREMENTS"), requirementController.getActiveApplicationPeriod);
router.put('/requirement-period', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_REQUIREMENTS"), requirementController.updateApplicationPeriod);

module.exports = router;

