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

        const dbResult = await organizationsModel.createOrganizationApplication(
            { 
                ...organization,
                organization_logo: logoFile.name
            },
            executives,
            requirements.map(req => ({
                requirement_id: req.requirement_id,
                requirement_path: req.requirement_path
            })),
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
                const filename = path.basename(req.requirement_path);
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



module.exports = {
    getOrganizations,
    createOrganizationApplication,
    getSpecificApplication
};