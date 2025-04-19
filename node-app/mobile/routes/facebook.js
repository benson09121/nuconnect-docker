const express = require('express');
const router = express.Router();
const facebookController = require('../controllers/facebookController');

router.get('/facebook_posts', facebookController.getFacebookPosts);

module.exports = router;
