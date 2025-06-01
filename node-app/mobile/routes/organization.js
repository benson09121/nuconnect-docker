const express = require('express');
const router = express.Router();
const organizationController = require('../controllers/organizationController');
const middleware = require('../../middlewares/middleWare');


router.get('/organizations', middleware.authMiddleware, organizationController.getOrganizations);
router.get('/organization-fee', middleware.authMiddleware, organizationController.getOrganizationFee);
router.get('/profile/organization', middleware.authMiddleware, organizationController.getUserOrganization);
router.get('/organization/question', middleware.authMiddleware, organizationController.getOrganizationQuestion);
router.post('/organization-application/submit', middleware.authMiddleware, organizationController.submitOrganizationApplication);

module.exports = router;
