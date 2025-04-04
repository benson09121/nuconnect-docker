const pool = require('../config/db');
const { redisClient } = require('../config/redis');
const { Auth } = require("../models/userIdModel");

async function getAllEvents() {
    const cacheKey = 'events:all';
    const cachedEvents = await redisClient.get(cacheKey);

    if (cachedEvents) {
        return JSON.parse(cachedEvents);
    }

    const connection = await pool.getConnection();
    try {
        const rows = await connection.query('CALL GetAllEvents;');

        // Cache the result in Redis
        await redisClient.set(cacheKey, JSON.stringify(rows[0][0]), 'EX', 3600); // Cache for 1 hour

        return rows[0][0];
    } finally {
        connection.release();
    }
}

async function refreshCache() {
    const connection = await pool.getConnection();
    try {
        const rows = await connection.query(`CALL GetAllEvents;`);

        // Update the cache in Redis
        await redisClient.set('events:all', JSON.stringify(rows[0][0]), 'EX', 3600); // Cache for 1 hour
    } finally {
        connection.release();
    }
}

async function createEvent(user_id, title, description, venue, date, start_time, end_time, organization_id, department_id, type, status) {
    const connection = await pool.getConnection();
    try {
        const [result] = await connection.query(
            'CALL CreateEvent(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);',
            [user_id, title, description, venue, date, start_time, end_time, organization_id, department_id ?? null,type ?? 'Free', status ?? 'Pending']
        );
        // Invalidate the cache
        await redisClient.del('events:all');
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
    if(cachedAttendees) {
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

module.exports = { getAllEvents, createEvent, registerEvent, archiveEvent, getSpecificEvent, getEventAttendees, refreshCache, refreshAttendeesCache, checkEventRegistration };
