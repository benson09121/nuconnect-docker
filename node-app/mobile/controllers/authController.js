const userModel = require('../models/userModel');
const jwt = require('jsonwebtoken');

async function login(req, res) {
    try {
        const { mail, surname, givenName, id } = req.body;
        console.log("Login request received:", { mail, surname, givenName, id });
        const result = await userModel.getUser(mail);
        if (result && result.length > 0) {
            const token = await userModel.generateToken(mail);
            res.json({ status: 200, message: "User Authenticated", token: token });
        }
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
}


module.exports = { login };
