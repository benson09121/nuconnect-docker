const express = require('express');
const router = express.Router();
const accountController = require('../controllers/accountController');
const middleware = require('../../middlewares/middleWare');


router.get('/manage/accounts', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_ACCOUNT"), accountController.getAccounts);
router.post('/manage/accounts', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_ACCOUNT"), accountController.addAccount);
router.delete('/manage/accounts/:email', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_ACCOUNT"), accountController.deleteAccount);
router.put('/manage/accounts/:email', middleware.validateAzureJWT, middleware.hasPermission("MANAGE_ACCOUNT"), accountController.unarchiveAccount);
module.exports = router;
