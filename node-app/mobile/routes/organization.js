const express = require('express');
const router = express.Router();
const organizationController = require('../controllers/organizationController');
const middleware = require('../../middlewares/middleWare');


router.get('/organizations', middleware.authMiddleware, organizationController.getOrganizations);
router.get('/profile/organization', middleware.authMiddleware, organizationController.getUserOrganization);

module.exports = router;
