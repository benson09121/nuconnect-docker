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

async function updateRequirement(requirement_id, requirement_name, file_path) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL UpdateRequirement(?, ?, ?);', [requirement_id, requirement_name, file_path]);
        return rows[0];
    }   
    catch (error) {
        console.error('Error updating requirement:', error);
        throw error;
    }
    finally {
        connection.release();
    }
}

async function addApplicationPeriod(startDate, endDate, startTime, endTime, user_id){
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL AddApplicationPeriod(?, ?, ?, ?, ?);', [startDate, endDate, startTime, endTime, user_id]);
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

async function getActiveApplicationPeriod(){
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetActiveApplicationPeriod();');
        return rows[0];
    }
    catch (error) {
        console.error('Error fetching active application period:', error);
        throw error;
    }
    finally {
        connection.release();
    }
}

async function updateApplicationPeriod(startDate, endDate, startTime, endTime, period_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL UpdateApplicationPeriod(?, ?, ?, ?);',[startDate, endDate, startTime, endTime, period_id]);
        return rows[0];
    }
    catch (error) {
        console.error('Error updating requirement period:', error);
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
    deleteRequirement,
    updateRequirement,
    addApplicationPeriod,
    getActiveApplicationPeriod,
    updateApplicationPeriod
};