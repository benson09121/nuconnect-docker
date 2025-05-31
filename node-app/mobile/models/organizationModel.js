const pool = require('../../config/db');
const { redisClient } = require('../../config/redis');
const { Auth } = require("./userIdModel");

async function getOrganizations() {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetOrganizations(?);', [Auth.get_userId]);
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
async function getOrganizationQuestion(org_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetOrganizationQuestion(?);', [org_id]);
        return rows[0];
    } finally {
        connection.release();
    }
}

module.exports = {
    getOrganizations,
    getUserOrganization,
    getOrganizationQuestion
};

