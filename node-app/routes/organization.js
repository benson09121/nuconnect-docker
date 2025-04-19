const express = require('express');
const router = express.Router();
const organizationController = require('../controllers/organizationController');
const authMiddleware = require('../middlewares/authMiddleware');



router.get('/organizations', authMiddleware, organizationController.getOrganizations);
router.get('/profile/organization', authMiddleware, organizationController.getUserOrganization);

module.exports = router;
