const pool = require('../../config/db');


async function createOrganizationApplication(organizations, executives,user_id){
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL CreateOrganizationApplication(?,?,?);', [organizations, executives,user_id]);
        return rows[0];
    }
    catch (error) {
        console.error('Error adding requirement period:', error);
        throw error;
    }
    finally {
        connection.release();
    }
}


module.exports = {
  createOrganization
};