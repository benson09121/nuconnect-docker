const express = require('express');
const router = express.Router();
const organizationsController = require('../../web/controllers/organizationsController');
const middleware = require('../../middlewares/middleWare');

// router.get('/organizations', middleware.validateAzureJWT, middleware.hasPermission("VIEW_ORGANIZATION"), organizationsController.getOrganizations);
router.get('/organizations-by-status', middleware.validateAzureJWT, middleware.hasPermission("VIEW_ORGANIZATION"), organizationsController.getOrganizationsByStatus);
router.post('/organizations', middleware.validateAzureJWT, organizationsController.createOrganizationApplication);
router.get('/organizations', middleware.validateAzureJWT, organizationsController.getOrganizations);
router.get('/organization-details', middleware.validateAzureJWT, organizationsController.getOrganizationDetails);
router.get('/organization-dashboard', middleware.validateAzureJWT, organizationsController.getOrganizationDashboardStats);
router.get(
  '/organization-event-applications',
  middleware.validateAzureJWT,
  organizationsController.getOrganizationEventApplications
);
router.get(
  '/event-requirement-submissions-by-organization',
  middleware.validateAzureJWT,
  organizationsController.getEventRequirementSubmissionsByOrganization
);

router.get('/getSpecificApplication', middleware.validateAzureJWT, organizationsController.getSpecificApplication);
router.get('/org-applications', middleware.validateAzureJWT, organizationsController.getOrganizationApplications);
router.post('/approve-application', middleware.validateAzureJWT, organizationsController.approveApplication);
router.post('/reject-application', middleware.validateAzureJWT, organizationsController.rejectApplication);
router.get('/getOrganizationRequirement', middleware.validateAzureJWT, organizationsController.getOrganizationRequirement);
router.get('/getOrganizationLogo', middleware.validateAzureJWT, organizationsController.getOrganizationLogo);
router.get('/check-org-name',middleware.validateAzureJWT, organizationsController.checkOrganizationName);
router.post('/check-org-emails', middleware.validateAzureJWT, organizationsController.checkOrganizationEmails);
router.post('/archive-organization', middleware.validateAzureJWT, middleware.hasPermission("ARCHIVE_ORGANIZATION"), organizationsController.archiveOrganization);
router.post('/unarchive-organization', middleware.validateAzureJWT, middleware.hasPermission("ARCHIVE_ORGANIZATION"), organizationsController.unarchiveOrganization);

module.exports = router