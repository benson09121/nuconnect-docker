const pool = require('../config/db');
const jwt = require('jsonwebtoken');
require('dotenv').config();

async function getUser(mail) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('SELECT * FROM tbl_user WHERE email = ?', [mail]);
        return rows;
    } finally {
        connection.release();
    }
}

async function generateToken(email) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('SELECT * FROM tbl_user WHERE email = ?', [email]);
        if (!rows || rows.length === 0) { // Ensure rows is not undefined or empty
            throw new Error('User not found');
        }
        const { user_id, email: userEmail, f_name, l_name } = rows[0]; // Use a different variable name for destructured email
        const result = { user_id, email: userEmail, f_name, l_name };
        const token = jwt.sign({ result }, process.env.JWT_SECRET, { expiresIn: '7d' });
        return token;
    } finally {
        connection.release();
    }
}

async function createUser(id, mail, surname, givenName) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            'INSERT INTO tbl_user (user_id, email, l_name, f_name) VALUES (?, ?, ?, ?)',
            [id, mail, surname, givenName]
        );
        return rows;
    } finally {
        connection.release();
    }
}

module.exports = { getUser, generateToken, createUser };
