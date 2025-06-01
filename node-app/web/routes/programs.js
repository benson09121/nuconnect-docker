const express = require('express');
const router = express.Router();
const programsController = require('../controllers/programsController');
const middleware = require('../../middlewares/middleWare');

router.get(
    '/programs',
    middleware.validateAzureJWT,
    middleware.hasPermission("VIEW_ORGANIZATION"),
    programsController.getAllPrograms
);

module.exports = router;