const pool = require('../../config/db');



async function getOrganizations(user_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetOrganizationsWeb(?);',[user_id]);
        return rows[0];
    } catch (error) {
        console.error('Error fetching organizations:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function createOrganizationApplication(organizations, executives, requirements, user_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL CreateOrganizationApplication(?,?,?,?);', [JSON.stringify(organizations), JSON.stringify(executives), JSON.stringify(requirements), user_id]);
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

async function getSpecificApplication(user_id, organization_name) {
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

async function getOrganizationApplications() {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetOrganizationApplications();');
        return rows[0];
    } catch (error) {
        console.error('Error fetching organization applications:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function checkOrganizationName(org_name) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL CheckOrganizationName(?);', [org_name]);
        return rows[0];
    } catch (error) {
        console.error('Error checking organization name:', error);
        throw error;
    } finally {
        connection.release();
    }

}
async function checkOrganizationEmails(org_emails) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL CheckOrganizationEmails(?);', [org_emails]);
        return rows[0];
    } catch (error) {
        console.error('Error checking organization emails:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function getOrganizationDetails(org_name){
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetOrganizationDetails(?);', [org_name]);
        return rows[0];
    } catch (error) {
        console.error('Error fetching organization details:', error);
        throw error;
    } finally {
        connection.release();
    }
}
      
async function getUserByEmail(email) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('SELECT * FROM tbl_user WHERE email = ?', [email]);
        return rows[0] || null;
    } finally {
        connection.release();
    }
}

async function archiveOrganization(organization_id, user_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL ArchiveOrganization(?, ?);', [organization_id, user_id]);
        return rows[0];
    } catch (error) {
        console.error('Error archiving organization:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function unarchiveOrganization(organization_id, user_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL UnarchiveOrganization(?, ?);', [organization_id, user_id]);
        return rows[0];
    } catch (error) {
        console.error('Error unarchiving organization:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function getOrganizationsByStatus(status) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetOrganizationsByStatus(?);', [status]);
        return rows[0];
    } catch (error) {
        console.error('Error fetching organizations by status:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function getOrganizationEventApplications(org_name) {
    const connection = await pool.getConnection();
    try {
        const [results] = await connection.query('CALL GetOrganizationEventApplications(?);', [org_name]);
        // MySQL returns multiple result sets for multi-SELECT procs
        return {
            applications: results[0],
            submissions: results[1]
        };
    } catch (error) {
        console.error('Error fetching organization event applications:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function getEventRequirementSubmissionsByOrganization(organization_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetEventRequirementSubmissionsByOrganization(?);', [organization_id]);
        return rows[0];
    } catch (error) {
        console.error('Error fetching event requirement submissions by organization:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function getOrganizationIdByName(org_name) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            'SELECT organization_id FROM tbl_organization WHERE name = ? LIMIT 1',
            [org_name]
        );
        return rows[0] ? rows[0].organization_id : null;
    } catch (error) {
        console.error('Error fetching organization_id by name:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function getOrganizationDashboardStats(organization_id) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query('CALL GetOrganizationDashboardStats(?);', [organization_id]);
        return rows[0][0]; // Single row with stats
    } catch (error) {
        console.error('Error fetching organization dashboard stats:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function createExecutiveMember({
    organization_id,
    cycle_number,
    email,
    program_name,
    role_title,
    rank_level,
    action_by_email
}) {
    const connection = await pool.getConnection();
    try {
        // Log the SQL call and parameters
        console.log('SQL CALL: CALL CreateExecutiveMember(?, ?, ?, ?, ?, ?, ?);', [
            organization_id,
            cycle_number,
            email,
            program_name,
            role_title,
            rank_level,
            action_by_email
        ]);
        await connection.query(
            `CALL CreateExecutiveMember(?, ?, ?, ?, ?, ?, ?)`,
            [
                organization_id,
                cycle_number,
                email,
                program_name,
                role_title,
                rank_level,
                action_by_email
            ]
        );
        // If no error, success
        return { message: 'Executive member added successfully.' };
    } catch (error) {
        throw error;
    } finally {
        connection.release();
    }
}

async function updateExecutiveMember({
    organization_id,
    cycle_number,
    email,
    program_name,
    role_title,
    rank_level,
    action_by_email
}) {
    const connection = await pool.getConnection();
    try {
        console.log('SQL CALL: CALL UpdateExecutiveMember(?, ?, ?, ?, ?, ?, ?);', [
            organization_id,
            cycle_number,
            email,
            program_name,
            role_title,
            rank_level,
            action_by_email
        ]);
        await connection.query(
            `CALL UpdateExecutiveMember(?, ?, ?, ?, ?, ?, ?)`,
            [
                organization_id,
                cycle_number,
                email,
                program_name,
                role_title,
                rank_level,
                action_by_email
            ]
        );
        return { message: 'Executive member updated successfully.' };
    } catch (error) {
        throw error;
    } finally {
        connection.release();
    }
}

async function archiveExecutiveMember({
    organization_id,
    cycle_number,
    email,
    action_by_email
}) {
    const connection = await pool.getConnection();
    try {
        console.log('SQL CALL: CALL ArchiveExecutiveMember(?, ?, ?, ?);', [
            organization_id,
            cycle_number,
            email,
            action_by_email
        ]);
        await connection.query(
            `CALL ArchiveExecutiveMember(?, ?, ?, ?)`,
            [
                organization_id,
                cycle_number,
                email,
                action_by_email
            ]
        );
        return { message: 'Executive member archived successfully.' };
    } catch (error) {
        throw error;
    } finally {
        connection.release();
    }
}

async function getOrganizationCommittees(organization_id, cycle_number) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            'CALL GetOrganizationCommittees(?, ?);',
            [organization_id, cycle_number]
        );
        return rows[0];
    } catch (error) {
        console.error('Error fetching organization committees:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function createCommittee({
    organization_id,
    cycle_number,
    committee_name,
    description,
    action_by_email
}) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            `CALL CreateCommittee(?, ?, ?, ?, ?)`,
            [
                organization_id,
                cycle_number,
                committee_name,
                description,
                action_by_email
            ]
        );
        // The procedure returns the new committee_id as a result set
        return rows[0][0]; // { committee_id: ... }
    } catch (error) {
        throw error;
    } finally {
        connection.release();
    }
}

async function updateCommittee({
    committee_id,
    new_name,
    new_description,
    action_by_email
}) {
    const connection = await pool.getConnection();
    try {
        console.log('[updateCommittee] SQL CALL: CALL UpdateCommittee(?, ?, ?, ?)', [
            committee_id,
            new_name,
            new_description,
            action_by_email
        ]);
        const [rows] = await connection.query(
            `CALL UpdateCommittee(?, ?, ?, ?)`,
            [
                committee_id,
                new_name,
                new_description,
                action_by_email
            ]
        );
        return rows[0][0]; // { rows_affected: ... }
    } catch (error) {
        console.error('[updateCommittee] SQL/Error:', error.sqlMessage || error.message, error);
        throw error;
    } finally {
        connection.release();
    }
}

async function archiveCommittee({
    committee_id,
    reason,
    archived_by_email
}) {
    const connection = await pool.getConnection();
    try {
        console.log('[archiveCommittee] SQL CALL: CALL ArchiveCommittee(?, ?, ?)', [
            committee_id,
            reason,
            archived_by_email
        ]);
        const [rows] = await connection.query(
            `CALL ArchiveCommittee(?, ?, ?)`,
            [
                committee_id,
                reason,
                archived_by_email
            ]
        );
        return rows[0][0]; // { committees_archived: ... }
    } catch (error) {
        console.error('[archiveCommittee] SQL/Error:', error.sqlMessage || error.message, error);
        throw error;
    } finally {
        connection.release();
    }
}

async function getCommitteeMembers(committee_id) {
    const connection = await pool.getConnection();
    try {
        console.log('[getCommitteeMembers] SQL CALL: CALL GetCommitteeMembers(?)', [committee_id]);
        const [results] = await connection.query(
            'CALL GetCommitteeMembers(?)',
            [committee_id]
        );
        // MySQL returns multiple result sets: [committeeInfo, members]
        return {
            committee: results[0]?.[0] || null,
            members: results[1] || []
        };
    } catch (error) {
        console.error('[getCommitteeMembers] SQL/Error:', error.sqlMessage || error.message, error);
        throw error;
    } finally {
        connection.release();
    }
}

async function addCommitteeMember({
    committee_id,
    user_email,
    role,
    action_by_email
}) {
    const connection = await pool.getConnection();
    try {
        console.log('[addCommitteeMember] SQL CALL: CALL AddCommitteeMember(?, ?, ?, ?)', [
            committee_id,
            user_email,
            role,
            action_by_email
        ]);
        const [rows] = await connection.query(
            `CALL AddCommitteeMember(?, ?, ?, ?)`,
            [
                committee_id,
                user_email,
                role,
                action_by_email
            ]
        );
        return rows[0][0]; // { committee_member_id: ... }
    } catch (error) {
        console.error('[addCommitteeMember] SQL/Error:', error.sqlMessage || error.message, error);
        throw error;
    } finally {
        connection.release();
    }
}
      
module.exports = {
    getOrganizations,
    createOrganizationApplication,
    getSpecificApplication,
    approveApplication,
    rejectApplication,
    getOrganizationApplications,
    checkOrganizationName,
    checkOrganizationEmails,
    getOrganizationDetails,
    getUserByEmail,
    archiveOrganization,
    unarchiveOrganization,
    getOrganizationsByStatus,
    getOrganizationEventApplications,
    getEventRequirementSubmissionsByOrganization,
    getOrganizationIdByName,
    getOrganizationDashboardStats,
    createExecutiveMember,
    updateExecutiveMember,
    archiveExecutiveMember,
    getOrganizationCommittees,
    createCommittee,
    updateCommittee,
    archiveCommittee,
    getCommitteeMembers,
    addCommitteeMember,

};
