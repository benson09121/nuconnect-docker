const axios = require('axios');
const fs = require('fs');
const path = require('path');

const organizationsModel = require('../models/organizationsModel');

async function getOrganizations(req, res) {
  try {
        //  const getOrganizations = await organizationsModel.getOrganizations();
         res.json(getOrganizations);
     } catch (error) {
         res.status(500).json({
             error: error.message || "An error occurred while fetching the active application period.",
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
    org_name = org_name ? org_name.toLowerCase().replace(/ /g, '-') : org_name;
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
    org_name = org_name ? org_name.toLowerCase().replace(/ /g, '-') : org_name;
    try {
        // Set CORS header for browser access
        res.header('Access-Control-Allow-Origin', 'http://localhost:5173');
        // Set Content-Disposition so browser handles as image (inline)
        res.setHeader('Content-Disposition', `inline; filename="${logo_name}"`);
        // X-Accel-Redirect for Nginx internal serving
        res.setHeader('X-Accel-Redirect', `/protected-organization-requirements/${org_name}/logo/${logo_name}`);
        res.end();
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the logo.",
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
    getOrganizationLogo
};