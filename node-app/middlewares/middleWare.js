const jwt = require("jsonwebtoken");
require("dotenv").config();
const { Auth } = require("../mobile/models/userIdModel");
const jwksClient = require("jwks-rsa");
const userModel = require("../web/models/userModel");

const authMiddleware = async (req, res, next) => {
  const token = req.headers["authorization"]?.split(" ")[1];
  if (!token) {
    return res.status(401).json({ message: "No token provided" });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(401).json({ message: "Invalid token" });
    }
    req.user = {
      id: decoded.result.user_id,
      email: decoded.result.email,
      first_name: decoded.result.f_name,
      last_name: decoded.result.l_name,
    };
    Auth.id = decoded.result.user_id;
    Auth.first_name = decoded.result.f_name;
    Auth.last_name = decoded.result.l_name;
    req.userId = decoded.result.user_id;
    next();
  });
};

const validateAzureJWT = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ error: 'Authorization header missing' });
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return res.status(401).json({ error: 'Token missing' });
    }

    const decoded = jwt.decode(token, { complete: true });
    if (!decoded || !decoded.header || !decoded.header.kid) {
      return res.status(401).json({ error: 'Invalid token structure' });
    }

    const client = jwksClient({
      jwksUri: 'https://login.microsoftonline.com/common/discovery/keys',
    });

    const key = await client.getSigningKey(decoded.header.kid);
    const publicKey = key.getPublicKey();

    const verified = jwt.verify(token, publicKey, {
      audience: process.env.AZURE_CLIENT_ID,
      issuer: `https://login.microsoftonline.com/${process.env.AZURE_TENANT_ID}/v2.0`,
    });

    
   
    req.user = {
      f_name: verified.name.split(',')[1],
      l_name: verified.name.split(',')[0],
      user_id: verified.sub, 
      email: verified.preferred_username,
    };
    next();
  } catch (error) {
    console.error('validateAzureJWT error:', error.message);
    res.status(401).json({ error: 'Invalid token' });
  }
};

const hasPermission = (requiredPermission) => async (req, res, next) => {
  try {
      const permissions = await userModel.getPermissions(req.user.user_id);
      const userPermissions = permissions[0]?.user_info?.permissions || [];
      if (!userPermissions.includes(requiredPermission)) {
          return res.status(403).json({ error: 'Access denied' });
      }
      next();
  } catch (error) {
      res.status(500).json({ error: error.message });
  }
};

module.exports = { authMiddleware, validateAzureJWT, hasPermission };



