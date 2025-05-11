const express = require('express');
const router = express.Router();
const permissionController = require('../controllers/permissionController');
const middleware = require('../../middlewares/middleWare');


router.get('/permissions', middleware.validateAzureJWT, permissionController.getPermissions);

module.exports = router;
