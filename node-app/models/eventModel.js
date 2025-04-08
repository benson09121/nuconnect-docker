const pool = require('../config/db');
const { redisClient } = require('../config/redis');
const { Auth } = require("../models/userIdModel");

async function getAllEvents() {
    // const cacheKey = `events:user:${Auth.get_userId}`;
    // const cachedEvents = await redisClient.get(cacheKey);

    // if (cachedEvents) {
    //     return JSON.parse(cachedEvents);
    // }

    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetAllEvents(?);', [Auth.get_userId]);

        // Cache the events for the user
        // await redisClient.set(cacheKey, JSON.stringify(rows), 'EX', 3600); // Cache for 1 hour
        return rows[0];
    } finally {
        connection.release();
    }
}

async function createEvent(user_id, title, description, venue, date, start_time, end_time, organization_id, status, type, is_open_to_all) {
    const connection = await pool.getConnection();
    try {
        const [result] = await connection.query(
            'CALL CreateEvent(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);',
            [user_id, title, description, venue, date, start_time, end_time, organization_id, status ?? 'Pending', type ?? 'Free', is_open_to_all ?? 1]// 1 - 0
        );
        // Invalidate the cache
        await redisClient.del(`events:user:${user_id}`);
        return result[0][0];
    } finally {
        connection.release();
    }
}

async function registerEvent(event_id) {
    const connection = await pool.getConnection();
    try {
        const [result] = await connection.query(
            'CALL RegisterEvent(?, ?)',
            [event_id, Auth.get_userId]
        );
        return result[0][0];
    } finally {
        connection.release();
    }
}

async function checkEventRegistration(event_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            'CALL CheckEventRegistration(?, ?)',
            [event_id, Auth.get_userId]
        );
        return rows[0][0];
    } finally {
        connection.release();
    }
}

async function archiveEvent(event_id) {
    const connection = await pool.getConnection();
    try {
        await connection.query(
            'UPDATE tbl_event SET status = "Archived" WHERE event_id = ?',
            [event_id]
        );

        // Invalidate the cache
        await redisClient.del('events:all');
    } finally {
        connection.release();
    }
}

async function getSpecificEvent(eventId, userId) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            'CALL GetSpecificEvent(?, ?)',
            [eventId, userId]
        );
        return rows[0][0];
    } finally {
        connection.release();
    }
}

async function getEventAttendees(eventId) {
    const cacheKey = `events:attendees:${eventId}`;
    const cachedAttendees = await redisClient.get(cacheKey);
    if (cachedAttendees) {
        return JSON.parse(cachedAttendees);
    }
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            'CALL GetEventAttendees(?);',
            [eventId]
        );
        return rows;
    } finally {
        connection.release();
    }
}

async function refreshAttendeesCache(eventId) {
    const connection = await pool.getConnection();
    try {
        const rows = await connection.query(`CALL GetEventAttendees(?);`,
            [eventId]
        );
        // Update the cache in Redis
        await redisClient.set(`events:attendees:${eventId}`, JSON.stringify(rows), 'EX', 3600);
    } finally {
        connection.release();
    }
}
async function getTickets() {
    const connection = await pool.getConnection();
    try {

        const [rows] = await connection.query("Call GetUserEventRegistrations(?);", [Auth.get_userId]);
        return rows[0];
    } finally {
        connection.release();
    }
}
async function getOrganizations() {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetOrganizations(?);', [Auth.get_userId]);
        return rows[0];
    } finally {
        connection.release();
    }
}
async function getUpcomingEvents() {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetUpcomingEvents(?);', [Auth.get_userId]);
        return rows[0];
    } finally {
        connection.release();
    }
}

async function getUserOrganization() {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetUserOrganization(?);', [Auth.get_userId]);
        return rows[0];
    } finally {
        connection.release();
    }
}
async function AddCertificate(event_id, filepath) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL AddCertificate(?, ?);', [event_id, filepath]);
        return rows[0];
    } finally {
        connection.release();
    }
}

module.exports = {
    getAllEvents,
    createEvent,
    registerEvent,
    archiveEvent,
    getSpecificEvent,
    getEventAttendees,
    refreshAttendeesCache,
    checkEventRegistration,
    getTickets,
    getOrganizations,
    getUpcomingEvents,
    getUserOrganization
};
