const pool = require('../../config/db');

async function addEvent(event) {
    const connection = await pool.getConnection();
    try {
        const sql = `INSERT INTO tbl_event (
            event_id, title, description, date, start_time, end_time, capacity,
            certificate, fee, is_open_to_all, organization_id, status, type, user_id,
            venue, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;
        const params = [
            event.event_id, event.title, event.description, event.date, event.start_time, event.end_time,
            event.capacity, event.certificate, event.fee, event.is_open_to_all, event.organization_id,
            event.status, event.type, event.user_id, event.venue, event.created_at
        ];
        const [result] = await connection.query(sql, params);
        return result;
    } finally {
        connection.release();
    }
}

async function getEvents() {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetEvents();');
        return rows[0];
    } finally {
        connection.release();
    }
}

async function getEventById(event_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetEventById(?);', [event_id]);
        return rows[0];
    } finally {
        connection.release();
    }
}

async function getEventsByStatus(status) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetEventsByStatus(?);', [status]);
        return rows[0];
    } finally {
        connection.release();
    }
}

async function updateEvent(event_id, event) {
    const connection = await pool.getConnection();
    try {
        const sql = `UPDATE tbl_event SET
            title = ?, description = ?, date = ?, start_time = ?, end_time = ?, capacity = ?,
            certificate = ?, fee = ?, is_open_to_all = ?, organization_id = ?, status = ?, type = ?,
            user_id = ?, venue = ?, created_at = ?
            WHERE event_id = ?`;
        const params = [
            event.title, event.description, event.date, event.start_time, event.end_time,
            event.capacity, event.certificate, event.fee, event.is_open_to_all, event.organization_id,
            event.status, event.type, event.user_id, event.venue, event.created_at, event_id
        ];
        const [result] = await connection.query(sql, params);
        return result;
    } finally {
        connection.release();
    }
}

async function deleteEvent(event_id) {
    const connection = await pool.getConnection();
    try {
        const [result] = await connection.query('DELETE FROM tbl_event WHERE event_id = ?', [event_id]);
        return result;
    } finally {
        connection.release();
    }
}

module.exports = {
    addEvent,
    getEvents,
    getEventById,
    updateEvent,
    deleteEvent,
    getEventsByStatus
};