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

async function getAllCommitteeMembers() {
    const connection = await pool.getConnection();
    try {
        console.log('[getAllCommitteeMembers] SQL CALL: CALL GetAllCommitteeMembers()');
        const [rows] = await connection.query('CALL GetAllCommitteeMembers()');
        return rows[0];
    } catch (error) {
        console.error('[getAllCommitteeMembers] SQL/Error:', error.sqlMessage || error.message, error);
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

async function updateCommitteeMember({
    committee_member_id,
    new_role,
    action_by_email
}) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            `CALL UpdateCommitteeMember(?, ?, ?)`,
            [committee_member_id, new_role, action_by_email]
        );
        return rows[0][0]; // { rows_affected: ... }
    } catch (error) {
        throw error;
    } finally {
        connection.release();
    }
}

async function archiveCommitteeMember({
    committee_member_id,
    reason,
    action_by_email
}) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            `CALL ArchiveCommitteeMember(?, ?, ?)`,
            [committee_member_id, reason, action_by_email]
        );
        return rows[0][0]; // { rows_archived: ... }
    } catch (error) {
        throw error;
    } finally {
        connection.release();
    }
}

async function getPendingOrganizationMembers(organization_id, cycle_number) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            'CALL GetPendingOrganizationMembers(?, ?);',
            [organization_id, cycle_number]
        );
        return rows[0];
    } catch (error) {
        console.error('Error fetching pending organization members:', error);
        throw error;
    } finally {
        connection.release();
    }
}
async function approveMembershipApplication(application_id, reviewer_email, remarks) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            'CALL ApproveMembershipApplication(?, ?, ?);',
            [application_id, reviewer_email, remarks]
        );
        return rows[0];
    } catch (error) {
        console.error('Error approving membership application:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function rejectMembershipApplication(application_id, reviewer_email, remarks) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            'CALL RejectMembershipApplication(?, ?, ?);',
            [application_id, reviewer_email, remarks]
        );
        return rows[0];
    } catch (error) {
        console.error('Error rejecting membership application:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function addOrganizationMember({
    organization_id,
    cycle_number,
    email,
    status,
    executive_role_id = null,
    action_by_email,
    program_name = null
}) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            'CALL AddOrganizationMember(?, ?, ?, ?, ?, ?, ?);',
            [
                organization_id,
                cycle_number,
                email,
                status,
                executive_role_id,
                action_by_email,
                program_name
            ]
        );
        return rows[0];
    } catch (error) {
        console.error('Error adding organization member:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function editOrganizationMember({
    current_email,
    new_email,
    new_program_name
}) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            'CALL EditOrganizationMember(?, ?, ?);',
            [current_email, new_email, new_program_name]
        );
        return rows[0];
    } catch (error) {
        console.error('Error editing organization member:', error);
        throw error;
    } finally {
        connection.release();
    }
}

async function archiveOrganizationMember({ member_id, archived_by_email }) {
    const connection = await pool.getConnection();
    try {
        const [rows] = await connection.query(
            'CALL ArchiveOrganizationMember(?, ?);',
            [member_id, archived_by_email]
        );
        return rows[0];
    } catch (error) {
        console.error('Error archiving organization member:', error);
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
    getAllCommitteeMembers,
    addCommitteeMember,
    updateCommitteeMember,
    archiveCommitteeMember,
    getPendingOrganizationMembers,
    approveMembershipApplication,
    rejectMembershipApplication,
    addOrganizationMember,
    editOrganizationMember,
    archiveOrganizationMember,

};
