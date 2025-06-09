const pool = require('../../config/db');

async function getAccounts() {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetManagedAccounts();');
        return rows[0];
    }
    catch (error) {
        console.error('Error getting permissions:', error);
        throw error;
    }
    finally {
        connection.release();
    }
}

    async function addAccount(email, role, program) {
        const connection = await pool.getConnection();
        try {
            const [rows] = await connection.query('CALL AddManagedAccount(?, ?, ?)', [email, role, program]);
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

    async function updateAccount(user_id, email, role, program, status) {
        const connection = await pool.getConnection();
        try {
            const [rows] = await connection.query(
                'CALL UpdateManagedAccount(?, ?, ?, ?, ?)',
                [user_id, email, role, program, status]
            );
            return rows[0];
        }
        catch (error) {
            console.error('Error updating account:', error);
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

    async function unarchiveAccount(user_id) {
        const connection = await pool.getConnection();
        try {
            const [rows] = await connection.query('CALL UnarchiveManagedAccount(?)', [user_id]);
            return rows[0];
        }
        catch (error) {
            console.error('Error unarchiving account:', error);
            throw error;
        }
        finally {
            connection.release();
        }
    }

    async function getPrograms() {
        const connection = await pool.getConnection();
        try {
            const [rows] = await connection.query('CALL GetPrograms();');
            return rows[0];
        }
        catch (error) {
            console.error('Error getting programs:', error);
            throw error;
        }
        finally {
            connection.release();
        }
    }
    async function getRoles() {
        const connection = await pool.getConnection();
        try {
            const [rows] = await connection.query('CALL GetRoles();');
            return rows[0];
        }
        catch (error) {
            console.error('Error getting roles:', error);
            throw error;
        }
        finally {
            connection.release();
        }
    }

module.exports = {
    getAccounts,
    addAccount,
    updateAccount,
    deleteAccount,
    unarchiveAccount,
    getPrograms,
    getRoles
};