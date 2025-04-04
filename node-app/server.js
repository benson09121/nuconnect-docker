const express = require('express');
const http = require('http');
const { initializeSocket } = require('./controllers/eventsController');
require('dotenv').config();
const db = require('./config/db');
const { redisClient } = require('./config/redis');

const app = express();
const server = http.createServer(app);

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Import routes
const indexRoutes = require('./routes/index');
const authRoutes = require('./routes/auth');
const facebookRoutes = require('./routes/facebook');
const eventRoutes = require('./routes/events');

// Use routes
app.use('/', indexRoutes);
app.use('/api/mobile', authRoutes);
app.use('/api/mobile', facebookRoutes);
app.use('/api/mobile', eventRoutes);

// Global error handler for unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason);
    // Application specific logging, throwing an error, or other logic here
});

// Start the server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`NU-Connect server is running on port ${PORT}`);
});