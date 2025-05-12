const msal = require('@azure/msal-node');
const axios = require('axios');
const userModel = require('../models/userModel');
require('dotenv').config();


async function getAccessToken(cca) {
    const response = await cca.acquireTokenByClientCredential({
        scopes: ["https://graph.microsoft.com/.default"],
    });
    return response.accessToken;
}

async function register(req, res) {
    const { email } = req.body;
    console.log(email);
    const msalConfig = {
        auth: {
            clientId: process.env.AZURE_CLIENT_ID,
            authority: `https://login.microsoftonline.com/${process.env.AZURE_TENANT_ID}`,
            clientSecret: process.env.AZURE_CLIENT_SECRET,
        }
    };

    const cca = new msal.ConfidentialClientApplication(msalConfig);

    try {
        const token = await getAccessToken(cca);
        console.log(token);
        await axios.post("https://graph.microsoft.com/v1.0/invitations",
            {
                "invitedUserEmailAddress": email,
                "inviteRedirectUrl": process.env.AZURE_REDIRECT_URL,
                "sendInvitationMessage": true,
            },
            {
                headers: {
                    Authorization: `Bearer ${token}`,
                    "Content-Type": "application/json",
                },
            }
        ).then((response) => {
            console.log(response);
        });


        res.status(200).json({
            message: "Invitation sent successfully"
        });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while sending the invitation.",
        });
    }
}

async function login(req, res) {
    try {
        const permissionResult = await userModel.handleLogin(req.user);
        
        // const isUserExist = await userModel.checkUserExists(req.user.email);
        // console.log(req.user);
        // if (isUserExist.length === 0) {
        //     console.log("Creating user");
        //     await userModel.createUser(req.user);
        // }
        // console.log("isUserExist", isUserExist);
        // if (!req.user || !req.user.user_id) {
        //     return res.status(400).json({ error: "User information missing from request." });
        // }
        // const permissionResult = await userModel.getPermissions(req.user.user_id);
        console.log(permissionResult);
        // Extract permissions array from the nested user_info object
        const permissions = permissionResult[0]?.user_info?.permissions || [];
        permissions.includes("WEB_ACCESS") ? res.status(200).json(permissionResult[0].user_info) : res.status(401).json({ message: "Access Denied" });
    }
    catch (error) {
        console.error("Error in login:", error);
        res.status(500).json({ error: error.message });
    }
}

module.exports = { register, login };