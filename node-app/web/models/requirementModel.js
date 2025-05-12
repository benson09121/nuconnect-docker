const pool = require('../../config/db');

async function addRequirement(requirement_name, savePath, user_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL AddRequirement(?, ?, ?)',[requirement_name, savePath, user_id]);
        return rows[0];
    }
    catch (error) {
        console.error('Error fetching permissions:', error);
        throw error;
    }
    finally {
        connection.release();
    }
}

async function getRequirements(){
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetRequirements();');
        return rows[0];
    }
    catch (error) {
        console.error('Error fetching requirements:', error);
        throw error;
    }
    finally {
        connection.release();
    }
}

async function getSpecificRequirement(requirement_id){
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetSpecificRequirement(?);', [requirement_id]);
        return rows[0];
    }
    catch (error) {
        console.error('Error fetching specific requirement:', error);
        throw error;
    }
    finally {
        connection.release();
    }
}

async function deleteRequirement(requirement_id){
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL DeleteRequirement(?);', [requirement_id]);
        return rows[0];
    }
    catch (error) {
        console.error('Error deleting requirement:', error);
        throw error;
    }
    finally {
        connection.release();
    }
}


module.exports = {
    addRequirement,
    getRequirements,
    getSpecificRequirement,
    deleteRequirement
};