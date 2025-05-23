const msal = require('@azure/msal-node');
const axios = require('axios');
const logModel = require('../models/logModel');

async function getLogs(req, res) {
    try {
        const logs = await logModel.getLogs();
        res.status(200).json(logs);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the logs.",
        });
    }
}

module.exports = {
    getLogs
}