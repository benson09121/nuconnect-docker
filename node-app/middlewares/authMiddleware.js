const jwt = require("jsonwebtoken");
require("dotenv").config();
const { Auth } = require("../models/userIdModel");

const authMiddleware = (req, res, next) => {
  const token = req.headers["authorization"]?.split(" ")[1]; // Extract token from "Bearer <token>"

  if (!token) {
    return res.status(401).json({ message: "No token provided" });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(401).json({ message: "Invalid token" });
    }
    Auth.id = decoded.result.user_id;
    Auth.first_name = decoded.result.f_name;
    Auth.last_name = decoded.result.l_name;
    req.userId = decoded.result.user_id;
    next();
  });
};

module.exports = authMiddleware;


