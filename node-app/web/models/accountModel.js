const pool = require('../../config/db');

async function getAccounts() {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetManagedAccounts()');
        return rows[0][0].result;
    }
    catch (error) {
        console.error('Error    ing permissions:', error);
        throw error;
    }
    finally {
        connection.release();
    }
}

 async function addAccount(email, role, program, f_name, l_name) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL AddManagedAccount(?, ?, ?, ?, ?)', [email, role, program, f_name, l_name]);
        return rows[0];
    }
    catch (error) {
        console.error('Error adding account:', error);
        throw error;
    }
    finally {
        connection.release();
    }
}

    async function deleteAccount(email) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL DeleteManagedAccount(?)', [email]);
        return rows[0];
    }
    catch (error) {
        console.error('Error deleting account:', error);
        throw error;
    }
    finally {
        connection.release();
    }
}

module.exports = {
    getAccounts,
    addAccount,
    deleteAccount,
};