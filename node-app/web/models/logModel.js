const pool = require('../../config/db');

async function getLogs() {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetLogs();');
        return rows;
    } finally {
        connection.release();
    }
}

module.exports = {
    getLogs,
};