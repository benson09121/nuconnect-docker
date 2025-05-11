const jwt = require("jsonwebtoken");
require("dotenv").config();
const jwksClient = require('jwks-rsa');

async function validateAzureJWT(req, res, next) {
    try {
        const token = req.headers.authorization.split(' ')[1];
        const decoded = jwt.decode(token, { complete: true });
        
        const client = jwksClient({
            jwksUri: 'https://login.microsoftonline.com/common/discovery/keys'
        });
        
        const key = await client.getSigningKey(decoded.header.kid);
        const publicKey = key.getPublicKey();
        
        const verified = jwt.verify(token, publicKey, {
            audience: process.env.AZURE_CLIENT_ID,
            issuer: `https://login.microsoftonline.com/${process.env.AZURE_TENANT_ID}/v2.0`
        });
        
        req.user = {
            azureSub: verified.sub,
            email: verified.preferred_username
        };
        next();
    } catch (error) {
        res.status(401).json({ error: 'Invalid token' });
    }
};



module.exports = validateAzureJWT;