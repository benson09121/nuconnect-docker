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
        // Parse form data
        const organization = JSON.parse(req.body.organization);
        const executives = JSON.parse(req.body.executives);
        const requirements = JSON.parse(req.body.requirements);
        
        // 1. Handle file arrays properly
        const logoFile = req.files?.logo; // Access first file in array
        const requirementFiles = {};

        // 2. Store requirement files with proper array access
        requirements.forEach(reqItem => {
            const fileKey = `requirement_${reqItem.requirement_id}`;
            if (req.files[fileKey]) {
                requirementFiles[reqItem.requirement_id] = req.files[fileKey];
            }
        });

        // 3. Validate required files
        if (!logoFile) {
            throw new Error('Organization logo is required');
        }

        // 4. Call stored procedure with correct filename reference
        const dbResult = await organizationsModel.createOrganizationApplication(
            { 
                ...organization,
                organization_logo: logoFile.name // Use original filename
            },
            executives,
            requirements.map(req => ({
                requirement_id: req.requirement_id,
                requirement_path: req.requirement_path // Correct property name
            })),
            req.user.user_id
        );
        // 5. Create directories using path from procedure result
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

        // 6. Extract filename from database result
        const logoFilename = path.basename(dbResult[0].logo_path);

        // 7. Save logo with validated path
        fs.writeFileSync(
            path.join(logoDir, logoFilename),
            logoFile.data
        );

        // 8. Save requirements with correct filename reference
        
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



module.exports = {
    getOrganizations,
    createOrganizationApplication
};