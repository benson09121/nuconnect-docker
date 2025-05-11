const express = require('express');
const middleware = require('./middlewares/middleWare');
const router = express.Router();

router.get('/', middleware.authMiddleware, (req, res) => {
    res.send('The API is WORKING!!!!! 🥳🥳🥳');
});

module.exports = router;
