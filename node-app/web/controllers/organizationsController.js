const axios = require('axios');
const fs = require('fs');
const path = require('path');

const organizationsModel = require('../models/organizationsModel');
const { get } = require('http');

async function getOrganizations(req, res) {
  try {
        const getOrganizations = await organizationsModel.getOrganizations(req.user.user_id);
         res.json(getOrganizations);
     } catch (error) {
         res.status(500).json({
             error: error.message || "An error occurred while fetching the active application period.",
         });
     }
}

async function getOrganizationDetails(req, res) {
    try {
        const { org_name } = req.query;
        const organizationDetails = await organizationsModel.getOrganizationDetails(org_name);
        if (organizationDetails.length === 0) {
            return res.status(404).json({ message: 'Organization not found' });
        }
        res.json(organizationDetails);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the organization details.",
        });
    }
}

async function createOrganizationApplication(req, res) {
    try {

        const organization = JSON.parse(req.body.organization);
        const executives = JSON.parse(req.body.executives);
        const requirements = JSON.parse(req.body.requirements);

        const logoFile = req.files?.logo; 
        const requirementFiles = {};

        requirements.forEach(reqItem => {
            const fileKey = `requirement_${reqItem.requirement_id}`;
            if (req.files[fileKey]) {
                requirementFiles[reqItem.requirement_id] = req.files[fileKey];
            }
        });

        if (!logoFile) {
            throw new Error('Organization logo is required');
        }

        // Generate filenames for requirements and use them for both DB and file upload
        const requirementFilePaths = requirements.map(req => {
            const file = requirementFiles[req.requirement_id];
            if (file) {
                const filename = `requirement-${Date.now()}-${req.requirement_path}`;
                return {
                    requirement_id: req.requirement_id,
                    requirement_path: filename
                };
            } else {
                return {
                    requirement_id: req.requirement_id,
                    requirement_path: req.requirement_path
                };
            }
        });

        const dbResult = await organizationsModel.createOrganizationApplication(
            { 
                ...organization,
                organization_logo: logoFile.name
            },
            executives,
            requirementFilePaths,
            req.user.user_id
        );

        const orgDir = path.join('/app/organizations', dbResult[0].directory_name);
        if(!fs.existsSync(orgDir)) {
            fs.mkdirSync(orgDir, { recursive: true });
        }
        
        const logoDir = path.join(orgDir, 'logo');
        if(!fs.existsSync(logoDir)) {
            fs.mkdirSync(logoDir, { recursive: true });
        }

        const requirementsDir = path.join(orgDir, 'requirements');
        fs.mkdirSync(logoDir, { recursive: true });
        fs.mkdirSync(requirementsDir, { recursive: true });

        const logoFilename = path.basename(dbResult[0].logo_path);

        fs.writeFileSync(
            path.join(logoDir, logoFilename),
            logoFile.data
        );
        
        requirements.forEach(req => {
            const file = requirementFiles[req.requirement_id];
            if (file) {
                const filename = requirementFilePaths.find(r => r.requirement_id === req.requirement_id)?.requirement_path;
                fs.writeFileSync(
                    path.join(requirementsDir, filename),
                    file.data
                );
            }
        });

        res.status(201).json({
            message: 'Organization application submitted successfully',
            data: {
                ...dbResult,
                logo_url: `/organizations/${dbResult[0].directory_name}/logo/${logoFilename}`
            }
        });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while creating the organization."
        });
    }
}

async function getSpecificApplication(req, res) {
    try {
        const { org_name } = req.query;

        const formattedOrgName = org_name.replace(/-/g, ' ');
        const application = await organizationsModel.getSpecificApplication(req.user.user_id, formattedOrgName);
        if (application.length === 0) {
            return res.status(404).json({ message: 'No application found' });
        }
        res.json(application);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the application.",
        });
    }
}

async function approveApplication(req, res) {
    try {
        const { approval_id, comments, organization_id, application_id } = req.body;
        // Do NOT send any response before this line!
        const result = await organizationsModel.approveApplication(approval_id, comments, organization_id, application_id);
        res.json({ message: 'Application approved successfully' });
    } catch (error) {   
        res.status(500).json({
            error: error.message || "An error occurred while approving the application.",
        });
    }
}

async function rejectApplication(req, res) {
    try {
        const { approval_id, comments, organization_id, application_id } = req.body;
        const result = await organizationsModel.rejectApplication(approval_id, comments, organization_id, application_id);
        res.json({ message: 'Application rejected successfully' });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while rejecting the application.",
        });
    }
}

async function getOrganizationRequirement(req, res) {
    const requirement_name  = req.query.requirement_name;
    let org_name = req.query.org_name;
    org_name = encodeURIComponent(org_name);  
    try {
        
        res.header('Access-Control-Allow-Origin', 'http://localhost:5173');
        res.setHeader('X-Accel-Redirect', `/protected-organization-requirements/${org_name}/requirements/${requirement_name}`);
        const match = requirement_name.match(/requirement-(\d+)-(.+)/);
        const downloadName = match[0];
        res.setHeader('Content-Disposition', `attachment; filename="${downloadName}"`);
        res.end();
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the requirements.",
        });
    }
}

async function getOrganizationLogo(req, res) {
    let org_name = req.query.org_name;
    let logo_name = req.query.logo_name;
    const org_name_encoded = encodeURIComponent(org_name);
    try {
        res.header('Access-Control-Allow-Origin', 'http://localhost:5173');
        // Set Content-Disposition so browser handles as image (inline) 
        res.setHeader('Content-Disposition', `inline; filename="${logo_name}"`);
        // X-Accel-Redirect for Nginx internal serving
        res.setHeader('X-Accel-Redirect', `/protected-organization-requirements/${org_name_encoded}/logo/${logo_name}`);
        res.end();
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the logo.",
        });
    }
}

async function getOrganizationApplications(req, res) {
    try {
        const applications = await organizationsModel.getOrganizationApplications();
        res.json(applications);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the organization applications.",
        });
    }
}

async function checkOrganizationName(req, res) {
    try {
        const { org_name } = req.query;
        const exists = await organizationsModel.checkOrganizationName(org_name);
        res.json({ exists });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while checking the organization name.",
        });
    }
}

async function checkOrganizationEmails(req, res) {
    try {
        const { emails } = req.body;
        // Fix: flatten if double-wrapped (array in array)
        let emailList = emails;
        if (Array.isArray(emails) && emails.length === 1 && Array.isArray(emails[0])) {
            emailList = emails[0];
        }
        const exists = await organizationsModel.checkOrganizationEmails(JSON.stringify(emailList));
        res.json({ exists });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while checking the organization emails.",
        });
    }   
}

async function archiveOrganization(req, res) {
    try {
        const { organization_id } = req.body;
        if (!organization_id) {
            return res.status(400).json({ message: 'Organization ID is required.' });
        }
        // Lookup user_id by email (optimized)
        const user = await organizationsModel.getUserByEmail(req.user.email);
        if (!user || !user.user_id) {
            return res.status(404).json({ message: 'User not found.' });
        }
        await organizationsModel.archiveOrganization(organization_id, user.user_id);
        res.status(200).json({ message: 'Organization archived successfully.' });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while archiving the organization.",
        });
    }
}

async function unarchiveOrganization(req, res) {
    try {
        const { organization_id } = req.body;
        if (!organization_id) {
            return res.status(400).json({ message: 'Organization ID is required.' });
        }
        // Lookup user_id by email (optimized)
        const user = await organizationsModel.getUserByEmail(req.user.email);
        if (!user || !user.user_id) {
            return res.status(404).json({ message: 'User not found.' });
        }
        await organizationsModel.unarchiveOrganization(organization_id, user.user_id);
        res.status(200).json({ message: 'Organization unarchived successfully.' });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while unarchiving the organization.",
        });
    }
}

async function getOrganizationsByStatus(req, res) {
    try {
        const { status } = req.query;
        if (!status) {
            return res.status(400).json({ error: "Status is required." });
        }
        const organizations = await organizationsModel.getOrganizationsByStatus(status);
        res.json(organizations);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching organizations by status.",
        });
    }
}

async function getOrganizationEventApplications(req, res) {
    try {
        const org_name = req.query.org_name;
        if (!org_name) {
            return res.status(400).json({ message: 'org_name is required.' });
        }
        const result = await organizationsModel.getOrganizationEventApplications(org_name);
        res.json(result);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching organization event applications.",
        });
    }
}

async function getEventRequirementSubmissionsByOrganization(req, res) {
    try {
        let organization_id = parseInt(req.query.organization_id);
        const org_name = req.query.org_name;

        // If org_name is provided, look up organization_id using the model function
        if (!organization_id && org_name) {
            organization_id = await organizationsModel.getOrganizationIdByName(org_name);
            if (!organization_id) {
                return res.status(404).json({ message: 'Organization not found.' });
            }
        }

        if (!organization_id) {
            return res.status(400).json({ message: 'organization_id or org_name is required.' });
        }

        const submissions = await organizationsModel.getEventRequirementSubmissionsByOrganization(organization_id);
        res.json(submissions);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching event requirement submissions by organization.",
        });
    }
}

async function getOrganizationDashboardStats(req, res) {
    try {
        let organization_id = parseInt(req.query.organization_id);
        const org_name = req.query.org_name;

        // If org_name is provided, look up organization_id using the model function
        if (!organization_id && org_name) {
            organization_id = await organizationsModel.getOrganizationIdByName(org_name);
            if (!organization_id) {
                return res.status(404).json({ message: 'Organization not found.' });
            }
        }

        if (!organization_id) {
            return res.status(400).json({ message: 'organization_id or org_name is required.' });
        }

        const stats = await organizationsModel.getOrganizationDashboardStats(organization_id);
        res.json(stats);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching organization dashboard stats.",
        });
    }
}

async function createExecutiveMember(req, res) {
    try {
        // Log the incoming request body and user
        console.log('Add Executive Member Request:', {
            body: req.body,
            user: req.user
        });

        const {
            organization_id,
            cycle_number,
            email,
            program_name,
            role_title,
            rank_level
        } = req.body;

        const action_by_email = req.user.email;

        const result = await organizationsModel.createExecutiveMember({
            organization_id,
            cycle_number,
            email,
            program_name,
            role_title,
            rank_level,
            action_by_email
        });

        res.status(201).json({
            message: result.message
        });
    } catch (error) {
        const sqlMessage = error.sqlMessage || error.message || 'An error occurred while adding executive member.';
        res.status(400).json({ error: sqlMessage });
    }
}

async function updateExecutiveMember(req, res) {
    try {
        console.log('Update Executive Member Request:', {
            body: req.body,
            user: req.user
        });

        const {
            organization_id,
            cycle_number,
            email,
            program_name,
            role_title,
            rank_level
        } = req.body;

        const action_by_email = req.user.email;

        const result = await organizationsModel.updateExecutiveMember({
            organization_id,
            cycle_number,
            email,
            program_name,
            role_title,
            rank_level,
            action_by_email
        });

        res.status(200).json({
            message: result.message
        });
    } catch (error) {
        const sqlMessage = error.sqlMessage || error.message || 'An error occurred while updating executive member.';
        res.status(400).json({ error: sqlMessage });
    }
}

async function archiveExecutiveMember(req, res) {
    try {
        console.log('Archive Executive Member Request:', {
            body: req.body,
            user: req.user
        });

        const {
            organization_id,
            cycle_number,
            email
        } = req.body;

        const action_by_email = req.user.email;

        const result = await organizationsModel.archiveExecutiveMember({
            organization_id,
            cycle_number,
            email,
            action_by_email
        });

        res.status(200).json({
            message: result.message
        });
    } catch (error) {
        const sqlMessage = error.sqlMessage || error.message || 'An error occurred while archiving executive member.';
        res.status(400).json({ error: sqlMessage });
    }
}

async function getOrganizationCommittees(req, res) {
    try {
        const { organization_id, cycle_number } = req.query;
        if (!organization_id || !cycle_number) {
            return res.status(400).json({ error: "organization_id and cycle_number are required." });
        }
        const committees = await organizationsModel.getOrganizationCommittees(organization_id, cycle_number);
        res.json(committees);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching organization committees.",
        });
    }
}

async function createCommittee(req, res) {
    try {
        const {
            organization_id,
            cycle_number,
            committee_name,
            description
        } = req.body;

        const action_by_email = req.user.email;

        const result = await organizationsModel.createCommittee({
            organization_id,
            cycle_number,
            committee_name,
            description,
            action_by_email
        });

        res.status(201).json({
            message: 'Committee created successfully.',
            committee_id: result.committee_id
        });
    } catch (error) {
        const sqlMessage = error.sqlMessage || error.message || 'An error occurred while creating the committee.';
        res.status(400).json({ error: sqlMessage });
    }
}

async function updateCommittee(req, res) {
    try {
        console.log('[UpdateCommittee] Request:', {
            body: req.body,
            user: req.user
        });

        const {
            committee_id,
            new_name,
            new_description
        } = req.body;

        const action_by_email = req.user.email;

        const result = await organizationsModel.updateCommittee({
            committee_id,
            new_name,
            new_description,
            action_by_email
        });

        res.status(200).json({
            message: 'Committee updated successfully.',
            rows_affected: result.rows_affected
        });
    } catch (error) {
        console.error('[UpdateCommittee] SQL/Error:', error.sqlMessage || error.message, error);
        const sqlMessage = error.sqlMessage || error.message || 'An error occurred while updating the committee.';
        res.status(400).json({ error: sqlMessage });
    }
}

async function archiveCommittee(req, res) {
    try {
        console.log('[ArchiveCommittee] Request:', {
            body: req.body,
            user: req.user
        });

        const {
            committee_id,
            reason
        } = req.body;

        const archived_by_email = req.user.email;

        const result = await organizationsModel.archiveCommittee({
            committee_id,
            reason,
            archived_by_email
        });

        res.status(200).json({
            message: 'Committee archived successfully.',
            committees_archived: result.committees_archived
        });
    } catch (error) {
        console.error('[ArchiveCommittee] SQL/Error:', error.sqlMessage || error.message, error);
        const sqlMessage = error.sqlMessage || error.message || 'An error occurred while archiving the committee.';
        res.status(400).json({ error: sqlMessage });
    }
}

async function getAllCommitteeMembers(req, res) {
    try {
        const members = await organizationsModel.getAllCommitteeMembers();
        res.json(members);
    } catch (error) {
        console.error('[GetAllCommitteeMembers] SQL/Error:', error.sqlMessage || error.message, error);
        res.status(400).json({
            error: error.sqlMessage || error.message || "An error occurred while fetching all committee members."
        });
    }
}

async function addCommitteeMember(req, res) {
    try {
        console.log('[AddCommitteeMember] Request:', {
            body: req.body,
            user: req.user
        });

        const {
            committee_id,
            user_email,
            role
        } = req.body;

        const action_by_email = req.user.email;

        const result = await organizationsModel.addCommitteeMember({
            committee_id,
            user_email,
            role,
            action_by_email
        });

        res.status(201).json({
            message: 'Committee member added successfully.',
            committee_member_id: result.committee_member_id
        });
    } catch (error) {
        console.error('[AddCommitteeMember] SQL/Error:', error.sqlMessage || error.message, error);
        const sqlMessage = error.sqlMessage || error.message || 'An error occurred while adding committee member.';
        res.status(400).json({ error: sqlMessage });
    }
}

async function updateCommitteeMember(req, res) {
    try {
        const { committee_member_id, new_role } = req.body;
        const action_by_email = req.user.email;
        const result = await organizationsModel.updateCommitteeMember({
            committee_member_id,
            new_role,
            action_by_email
        });
        res.status(200).json({
            message: 'Committee member updated successfully.',
            rows_affected: result.rows_affected
        });
    } catch (error) {
        const sqlMessage = error.sqlMessage || error.message || 'An error occurred while updating committee member.';
        res.status(400).json({ error: sqlMessage });
    }
}

async function archiveCommitteeMember(req, res) {
    try {
        const { committee_member_id, reason } = req.body;
        const action_by_email = req.user.email;
        const result = await organizationsModel.archiveCommitteeMember({
            committee_member_id,
            reason,
            action_by_email
        });
        res.status(200).json({
            message: 'Committee member archived successfully.',
            rows_archived: result.rows_archived
        });
    } catch (error) {
        const sqlMessage = error.sqlMessage || error.message || 'An error occurred while archiving committee member.';
        res.status(400).json({ error: sqlMessage });
    }
}

async function getPendingOrganizationMembers(req, res) {
    try {
        const { organization_id, cycle_number } = req.query;
        if (!organization_id || !cycle_number) {
            return res.status(400).json({ error: "organization_id and cycle_number are required." });
        }
        const members = await organizationsModel.getPendingOrganizationMembers(organization_id, cycle_number);
        res.json(members);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching pending organization members.",
        });
    }
}
async function approveMembershipApplication(req, res) {
    try {
        const { application_id, remarks } = req.body;
        const reviewer_email = req.user.email;
        if (!application_id) {
            return res.status(400).json({ error: "application_id is required." });
        }
        await organizationsModel.approveMembershipApplication(application_id, reviewer_email, remarks || null);
        res.json({ message: 'Membership application approved successfully.' });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while approving the membership application.",
        });
    }
}

async function rejectMembershipApplication(req, res) {
    try {
        const { application_id, remarks } = req.body;
        const reviewer_email = req.user.email;
        if (!application_id) {
            return res.status(400).json({ error: "application_id is required." });
        }
        await organizationsModel.rejectMembershipApplication(application_id, reviewer_email, remarks || null);
        res.json({ message: 'Membership application rejected successfully.' });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while rejecting the membership application.",
        });
    }
}

async function addOrganizationMember(req, res) {
    try {
        const {
            organization_id,
            cycle_number,
            email,
            status,
            executive_role_id,
            program_name
        } = req.body;
        const action_by_email = req.user.email;

        if (!organization_id || !cycle_number || !email || !status) {
            return res.status(400).json({ error: "organization_id, cycle_number, email, and status are required." });
        }

        await organizationsModel.addOrganizationMember({
            organization_id,
            cycle_number,
            email,
            status,
            executive_role_id,
            action_by_email,
            program_name
        });

        res.status(201).json({ message: 'Organization member added successfully.' });
    } catch (error) {
        res.status(400).json({
            error: error.sqlMessage || error.message || "An error occurred while adding the organization member."
        });
    }
}

async function editOrganizationMember(req, res) {
    try {
        const { current_email, new_email, new_program_name } = req.body;
        if (!current_email || !new_email) {
            return res.status(400).json({ error: "current_email and new_email are required." });
        }
        await organizationsModel.editOrganizationMember({
            current_email,
            new_email,
            new_program_name
        });
        res.status(200).json({ message: 'Organization member updated successfully.' });
    } catch (error) {
        res.status(400).json({
            error: error.sqlMessage || error.message || "An error occurred while editing the organization member."
        });
    }
}

async function archiveOrganizationMember(req, res) {
    try {
        const { member_id } = req.body;
        if (!member_id) {
            return res.status(400).json({ error: "member_id is required." });
        }
        const archived_by_email = req.user.email;
        await organizationsModel.archiveOrganizationMember({ member_id, archived_by_email });
        res.status(200).json({ message: 'Organization member archived successfully.' });
    } catch (error) {
        res.status(400).json({
            error: error.sqlMessage || error.message || "An error occurred while archiving the organization member."
        });
    }
}


module.exports = {
    getOrganizations,
    createOrganizationApplication,
    getSpecificApplication,
    approveApplication,
    rejectApplication,
    getOrganizationRequirement,
    getOrganizationLogo,
    getOrganizationApplications,
    checkOrganizationName,
    checkOrganizationEmails,
    getOrganizationDetails,
    archiveOrganization,
    unarchiveOrganization,
    getOrganizationsByStatus,
    getOrganizationEventApplications,
    getEventRequirementSubmissionsByOrganization,
    getOrganizationDashboardStats,
    createExecutiveMember,
    updateExecutiveMember,
    archiveExecutiveMember,
    createCommittee,
    getOrganizationCommittees,
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