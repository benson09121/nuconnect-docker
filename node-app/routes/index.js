const express = require('express');
const authMiddleware = require('../middlewares/authMiddleware');
const router = express.Router();

router.get('/', authMiddleware, (req, res) => {
    res.send('Hello World');
});

module.exports = router;
