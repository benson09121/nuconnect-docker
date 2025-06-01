const pool = require('../../config/db');

async function getAllPrograms() {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetAllPrograms();');
        return rows[0];
    } catch (error) {
        throw error;
    } finally {
        connection.release();
    }
}

module.exports = {
    getAllPrograms,
};