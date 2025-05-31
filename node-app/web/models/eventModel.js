const pool = require('../../config/db');

async function addEvent(event) {
    const connection = await pool.getConnection();
    try {
        const sql = `INSERT INTO tbl_event (
            event_id, title, description, date, start_time, end_time, capacity,
            certificate, fee, is_open_to_all, organization_id, status, type, user_id,
            venue, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;
        const params = [
            event.event_id, event.title, event.description, event.date, event.start_time, event.end_time,
            event.capacity, event.certificate, event.fee, event.is_open_to_all, event.organization_id,
            event.status, event.type, event.user_id, event.venue, event.created_at
        ];
        const [result] = await connection.query(sql, params);
        return result;
    } finally {
        connection.release();
    }
}

async function getEventRequirements() {
  const connection = await pool.getConnection();
  try {
    const [rows] = await connection.query('CALL GetEventRequirements();');
    return rows[0];
  } finally {
    connection.release();
  }
}

async function saveEventRequirements(user_id, requirements) {
  const connection = await pool.getConnection();
  try {
    // requirements should be a JS array; stringify for MySQL JSON
    const [result] = await connection.query(
      'CALL SaveEventRequirements(?, ?);',
      [user_id, JSON.stringify(requirements)]
    );
    return result;
  } finally {
    connection.release();
  }
}

async function getEvents() {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetEvents();');
        return rows[0];
    } finally {
        connection.release();
    }
}

async function getEventById(event_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetEventById(?);', [event_id]);
        return rows[0];
    } finally {
        connection.release();
    }
}

async function getAttendeesByEventId(event_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetEventAttendeesWithDetails(?);', [event_id]);
        return rows[0];
    } finally {
        connection.release();
    }
}

async function getEventsByStatus(status) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetEventsByStatus(?);', [status]);
        return rows[0];
    } finally {
        connection.release();
    }
}

async function getPastEvents() {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetPastEvents();');
        return rows[0] || []; 
    } catch (error) {
        throw error;
    } finally {
        connection.release();
    }
}

async function updateEvent(event_id, event) {
    const connection = await pool.getConnection();
    try {
        const sql = `UPDATE tbl_event SET
            title = ?, description = ?, date = ?, start_time = ?, end_time = ?, capacity = ?,
            certificate = ?, fee = ?, is_open_to_all = ?, organization_id = ?, status = ?, type = ?,
            user_id = ?, venue = ?, created_at = ?
            WHERE event_id = ?`;
        const params = [
            event.title, event.description, event.date, event.start_time, event.end_time,
            event.capacity, event.certificate, event.fee, event.is_open_to_all, event.organization_id,
            event.status, event.type, event.user_id, event.venue, event.created_at, event_id
        ];
        const [result] = await connection.query(sql, params);
        return result;
    } finally {
        connection.release();
    }
}

async function deleteEvent(event_id) {
    const connection = await pool.getConnection();
    try {
        const [result] = await connection.query('DELETE FROM tbl_event WHERE event_id = ?', [event_id]);
        return result;
    } finally {
        connection.release();
    }
}

async function getUserByEmail(email) {
  const connection = await pool.getConnection();
  try {
    const [rows] = await connection.query('SELECT user_id FROM tbl_user WHERE email = ?', [email]);
    return rows[0];
  } finally {
    connection.release();
  }
}

async function approvePaidEventRegistration(event_id, user_id, approver_id, remarks) {
    const connection = await pool.getConnection();
    try {
        const [result] = await connection.query(
            'CALL ApprovePaidEventRegistration(?, ?, ?, ?);', 
            [event_id, user_id, approver_id, remarks]
        );
        return result;
    } finally {
        connection.release();
    }
}

async function rejectPaidEventRegistration(event_id, user_id, approver_id, remarks) {
    const connection = await pool.getConnection();
    try {
        const [result] = await connection.query(
            'CALL RejectPaidEventRegistration(?, ?, ?, ?);', 
            [event_id, user_id, approver_id, remarks]
        );
        return result;
    } finally {
        connection.release();
    }
}

async function getEventStats(event_id) {
  const connection = await pool.getConnection();
  try {
    const [rows] = await connection.query('CALL GetEventStatsForComponent(?)', [event_id]);
    return rows[0][0];
  } finally {
    connection.release();
  }
}

async function getAllEvaluationQuestions() {
  const connection = await pool.getConnection();
  try {
    const [rows] = await connection.query('CALL GetAllEvaluationQuestions();');
    return rows[0]; 
  } finally {
    connection.release();
  }
}

async function getEventEvaluationResponsesByGroup(event_id) {
  const connection = await pool.getConnection();
  try {
    const [rows] = await connection.query('CALL GetEventEvaluationResponsesByGroup(?);', [event_id]);
    if (rows[0] && rows[0][0] && rows[0][0].evaluation_responses) {
      const data = rows[0][0].evaluation_responses;
      if (typeof data === 'string') {
        return JSON.parse(data);
      }
      return data;
    }
    return [];
  } finally {
    connection.release();
  }
}

async function getEventApplicationDetails(event_application_id) {
  const connection = await pool.getConnection();
  try {
    const [results] = await connection.query('CALL GetEventApplicationDetails(?);', [event_application_id]);
    // MySQL returns multiple result sets for each SELECT in the procedure
    return {
      application: results[0][0] || null,
      requirements: results[1] || [],
      approvals: results[2] || []
    };
  } finally {
    connection.release();
  }
}

async function getEventApplicationIdByProposedEventId(proposed_event_id) {
  const [rows] = await pool.query(
    'SELECT event_application_id FROM tbl_event_application WHERE proposed_event_id = ? LIMIT 1',
    [proposed_event_id]
  );
  return rows.length > 0 ? rows[0].event_application_id : null;
}

async function createEventApplication(
  organization_id,
  cycle_number,
  applicant_user_id,
  event,
  requirements
) {
  const connection = await pool.getConnection();
  try {
    const [result] = await connection.query(
      'CALL CreateEventApplication(?, ?, ?, ?, ?);',
      [
        organization_id,
        cycle_number,
        applicant_user_id,
        JSON.stringify(event),
        JSON.stringify(requirements)
      ]
    );
    return result[0];
  } finally {
    connection.release();
  }
}

async function getOrganizationMembership(user_id) {
  const connection = await pool.getConnection();
  try {
    const [rows] = await connection.query(
      'SELECT organization_id, cycle_number FROM tbl_organization_members WHERE user_id = ? ORDER BY joined_at DESC LIMIT 1',
      [user_id]
    );
    return rows[0] || null;
  } finally {
    connection.release();
  }
}

async function approveEventApplication(approval_id, comment, event_application_id, user_id) {
  const connection = await pool.getConnection();
  try {
    const [result] = await connection.query(
      'CALL ApproveEventApplication(?, ?, ?, ?);',
      [approval_id, comment, event_application_id, user_id]
    );
    return result;
  } finally {
    connection.release();
  }
}

async function rejectEventApplication(approval_id, event_application_id, comment, user_id) {
  const connection = await pool.getConnection();
  try {
    const [result] = await connection.query(
      'CALL RejectEventApplication(?, ?, ?, ?);',
      [approval_id, event_application_id, comment, user_id]
    );
    return result;
  } finally {
    connection.release();
  }
}

async function getEventEvaluationConfig(event_id) {
  const connection = await pool.getConnection();
  try {
    const [results] = await connection.query('CALL GetEventEvaluationConfig(?);', [event_id]);
    // MySQL returns multiple result sets for each SELECT in the procedure
    return {
      settings: results[0][0] || null,
      enabledGroups: results[1] || [],
      allGroups: results[2] || []
    };
  } finally {
    connection.release();
  }
}

async function updateEventEvaluationConfig(event_id, group_ids, evaluation_end_date, evaluation_end_time, user_id) {
  const connection = await pool.getConnection();
  try {
    const [result] = await connection.query(
      'CALL UpdateEventEvaluationConfig(?, ?, ?, ?, ?);',
      [
        event_id,
        JSON.stringify(group_ids),
        evaluation_end_date,
        evaluation_end_time,
        user_id
      ]
    );
    return result;
  } finally {
    connection.release();
  }
}

async function uploadOrUpdatePostEventRequirement({
  event_id,
  event_application_id,
  requirement_id,
  cycle_number,
  organization_id,
  file_path,
  submitted_by
}) {
  const connection = await pool.getConnection();
  try {
    const [result] = await connection.query(
      'CALL UploadOrUpdatePostEventRequirement(?, ?, ?, ?, ?, ?, ?);',
      [
        event_id,
        event_application_id,
        requirement_id,
        cycle_number,
        organization_id,
        file_path,
        submitted_by
      ]
    );
    return result;
  } finally {
    connection.release();
  }
}

async function getEventRequirementSubmissions({
  event_id,
  event_application_id = null,
  requirement_id = null,
  submitted_by = null
}) {
  const connection = await pool.getConnection();
  try {
    const [rows] = await connection.query(
      'CALL GetEventRequirementSubmissions(?, ?, ?, ?);',
      [event_id, event_application_id, requirement_id, submitted_by]
    );
    return rows[0];
  } finally {
    connection.release();
  }
}

module.exports = {
    addEvent,
    getEventRequirements,
    saveEventRequirements,
    getEvents,
    getEventById,
    getPastEvents,
    getAttendeesByEventId,
    updateEvent,
    deleteEvent,
    getEventsByStatus,
    getUserByEmail,
    approvePaidEventRegistration,
    rejectPaidEventRegistration,
    getEventStats,
    getAllEvaluationQuestions,
    getEventEvaluationResponsesByGroup,
    getEventApplicationDetails,
    getEventApplicationIdByProposedEventId,
    createEventApplication,
    getOrganizationMembership,
    approveEventApplication,
    rejectEventApplication,
    getEventEvaluationConfig,
    updateEventEvaluationConfig,
    uploadOrUpdatePostEventRequirement,
    getEventRequirementSubmissions,
};