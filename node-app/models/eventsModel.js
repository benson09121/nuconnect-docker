const con = require("../config/db");
const { Auth } = require("../models/userIdModel");

async function getAllEvents() {
  return new Promise((resolve, reject) => {
    con.query(
      `SELECT 
    a.event_id, 
    a.title, 
    a.user_id, 
    a.description, 
    a.start_time, 
    a.end_time, 
    a.date, 
    a.created_at, 
    b.f_name, 
    b.l_name, 
    COALESCE(c.status, 'Not Registered') AS status
FROM tbl_event a
INNER JOIN tbl_user b ON a.user_id = b.user_id
LEFT JOIN tbl_event_attendance c 
    ON c.event_id = a.event_id 
    AND c.user_id = ?`,
      [Auth.get_userId],
      (err, rows) => {
        if (err) return reject(err);
        resolve(rows);
      }
    );
  });
}

async function createEvent(
  user_id,
  title,
  description,
  venue,
  date,
  start_time,
  end_time
) {
  return new Promise((resolve, reject) => {
    con.query(
      "INSERT INTO tbl_event (user_id, title, description, venue, date, start_time, end_time) VALUES (?, ?, ?, ?, ?, ?, ?)",
      [user_id, title, description, venue, date, start_time, end_time],
      (err, result) => {
        if (err) return reject(err);
      con.query(`
        SELECT 
    a.event_id, 
    a.title, 
    a.user_id, 
    a.description, 
    a.start_time, 
    a.end_time, 
    a.date, 
    a.created_at, 
    b.f_name, 
    b.l_name, 
    COALESCE(c.status, 'Not Registered') AS status
FROM tbl_event a
INNER JOIN tbl_user b ON a.user_id = b.user_id
LEFT JOIN tbl_event_attendance c 
    ON c.event_id = a.event_id 
    AND c.user_id = ? WHERE a.event_id = ?`,
        [Auth.get_userId, result.insertId], (err, rows) => {
          if (err) return reject(err);
          resolve(rows[0]);
        });
      }
    );
  });
}

async function registerEvent(event_id) {
  return new Promise((resolve, reject) => {
    con.query(
      "INSERT INTO tbl_event_attendance (event_id, user_id,status) VALUES (?, ?, ?)",
      [event_id, Auth.get_userId, "Going"],
      (err, result) => {
        if (err) return reject(err);
        resolve(result);
      }
    );
  });
}

module.exports = { getAllEvents, createEvent, registerEvent };
