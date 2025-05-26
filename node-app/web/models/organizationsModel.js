const pool = require('../../config/db');


async function createOrganizationApplication(organizations, executives, requirements,user_id){
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL CreateOrganizationApplication(?,?,?,?);', [JSON.stringify(organizations),JSON.stringify(executives), JSON.stringify(requirements),user_id]);
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

async function getSpecificApplication(user_id, organization_name){
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetSpecificApplication(?, ?);', [user_id, organization_name]);
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

async function approveApplication(approval_id, comments, organization_id, application_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL ApproveApplication(?, ?, ?, ?);', [approval_id, comments, organization_id, application_id]);
        return rows[0];
    } catch (error) {
        console.error('Error approving application:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function rejectApplication(approval_id, comments, organization_id, application_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL RejectApplication(?, ?, ?, ?);', [application_id, approval_id, organization_id, comments]);
        return rows[0];
    } catch (error) {
        console.error('Error rejecting application:', error);
        throw error;
    } finally {
        connection.release();
    }
}

module.exports = {
  createOrganizationApplication,
  getSpecificApplication,
  approveApplication,
  rejectApplication
};