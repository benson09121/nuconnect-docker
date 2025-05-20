const msal = require('@azure/msal-node');
const axios = require('axios');
const organizationsModel = require('../models/organizationsModel');

async function getOrganizations(req, res) {
  try {
         const getOrganizations = await organizationsModel.getOrganizations();
         res.json(getOrganizations);
     } catch (error) {
         res.status(500).json({
             error: error.message || "An error occurred while fetching the active application period.",
         });
     }
}

async function addOrganizationRequirement(requirement_id, requirement_name ,requirement_file, user_id) {
    // Reference: eventsController.js addCertificate
    try {
        

        // Save file to disk
        const requirementsDir = '/app/Organizations/OrganizationNameHere/requirements/';
        if (!fs.existsSync(requirementsDir)) {
            fs.mkdirSync(requirementsDir, { recursive: true });
        }
        const filename = `orgrequirement-${Date.now()}-${uploadedFile.name}`;
        const savePath = path.join(requirementsDir, filename);

        try {
            fs.writeFileSync(savePath, uploadedFile.data);
        } catch (writeError) {
            return res.status(500).json({ message: 'Error saving file', error: writeError.message });
        }

        await requirementModel.addRequirement(requirement_name, filename, req.user.user_id);
        res.status(201).json({ message: 'Requirement uploaded successfully'});
    } catch (err) {
        console.log(err);
        return res.status(500).json({ message: "Internal server error" });
    }
}

async function createOrganizationApplication(req, res) {
    const { organizations, executives, requirements } = req.body;
    try {
        const newOrganization = await organizationsModel.createOrganizationApplication(organizations, executives,req.user.user_id);
        //get the Organization name on the newOrganization
        requirements.map( async (requirement) => {
            await addOrganizationRequirement(requirement.id, requirement.requirement_path, requirement.requirement_file, req.user.user_id);
        });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while creating the organization.",
        });
    }
}



module.exports = {
    getOrganizations,
    createOrganizationApplication
};