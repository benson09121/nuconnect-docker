const express = require('express');
const http = require('http');
const { initializeSocket } = require('./mobile/controllers/eventsController');
require('dotenv').config();
const db = require('./config/db');
const fileUpload = require('express-fileupload');
const { redisClient } = require('./config/redis');
// const { scanner } = require('./config/clamav');
const cors = require('cors');

const app = express();
const server = http.createServer(app);

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(fileUpload({
    limits: {fileSize: 100 * 1024 * 1024},
    abortOnLimit: true, 
    safeFileNames: true,
    preserveExtension: true,
    createParentPath: true,
}));
app.use(cors({
    origin: "http://localhost:5173",
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    credentials: true,
}));


// Import Routes on Mobile
const indexRoutes = require('./index');
const authRoutes = require('./mobile/routes/auth');
const facebookRoutes = require('./mobile/routes/facebook');
const eventRoutes = require('./mobile/routes/events');
const organizationRoutes = require('./mobile/routes/organization');


// Import Routes on Web
const authRoutesWeb = require('./web/routes/auth');
const permissionRoutesWeb = require('./web/routes/permissions'); 
const manageAccountsRoutesWeb = require('./web/routes/manageAccounts');
const RequirementsWb = require('./web/routes/requirements');

// Routes on Mobile
app.use('/', indexRoutes);
app.use('/api/mobile', authRoutes);
app.use('/api/mobile', facebookRoutes);
app.use('/api/mobile', eventRoutes);
app.use('/api/mobile', organizationRoutes);

// Routes on Web
app.use('/api/web', authRoutesWeb);
app.use('/api/web', permissionRoutesWeb);
app.use('/api/web', manageAccountsRoutesWeb);
app.use('/api/web', RequirementsWb);


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