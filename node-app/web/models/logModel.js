const pool = require('../../config/db');

async function getLogs({ user_id = null, type = null, start_date = null, end_date = null } = {}) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            'CALL GetLogs(?, ?, ?, ?);',
            [user_id, type, start_date, end_date]
        );
        return rows[0]; // Only the first result set contains the logs
    } finally {
        connection.release();
    }
}

module.exports = {
    getLogs,
};