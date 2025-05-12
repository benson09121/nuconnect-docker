const requirementModel = require('../models/requirementModel');
const path = require('path');
const fs = require('fs');

async function addRequirement(req, res) {
    // Reference: eventsController.js addCertificate
    try {
        const { requirement_name } = req.body;

        if (!req.files || !req.files.template) {
            return res.status(400).json({ message: 'No file uploaded' });
        }

        const uploadedFile = req.files.template;

        // Optionally validate file type here if needed
        // Example: Only allow PDFs
        // if (uploadedFile.mimetype !== 'application/pdf') {
        //     return res.status(400).json({ message: 'Only PDF files allowed' });
        // }

        // Save file to disk
        const requirementsDir = '/app/requirements';
        if (!fs.existsSync(requirementsDir)) {
            fs.mkdirSync(requirementsDir, { recursive: true });
        }
        const filename = `requirement-${Date.now()}-${uploadedFile.name}`;
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

async function getRequirements(req, res) {
    try {
        const requirements = await requirementModel.getRequirements();
        res.json(requirements);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the requirements.",
        });
    }

}
async function downloadTemplate(req, res) {
    const template_name  = req.query.template_name;
    console.log(template_name);
    try {
        res.header('Access-Control-Allow-Origin', 'http://localhost:5173');
        res.setHeader('X-Accel-Redirect', `/protected-requirements/${template_name}`);
        const match = template_name.match(/requirement-(\d+)-(.+)/);
        // Use the original filename if available, fallback to template_name
        const downloadName = match[0];
        res.setHeader('Content-Disposition', `attachment; filename="${downloadName}"`);
        // Optionally, send a short message for debugging (remove in production)
        // res.end('File download triggered');
        res.end();
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the requirements.",
        });
    }
}

async function deleteRequirement(req, res) {
    try {
        const requirement_id = req.query.requirement_id;
        // Get the requirement to find the filename
        const [requirement] = await requirementModel.getSpecificRequirement(requirement_id);
        if (!requirement) {
            return res.status(404).json({ message: requirement_id });
        }

        const result = await requirementModel.deleteRequirement(requirement_id);


            const filename = requirement.file_path;
            if (filename) {
                const filePath = path.join('/app/requirements', filename);
                try {
                    if (fs.existsSync(filePath)) {
                        fs.unlinkSync(filePath);
                    }
                } catch (fileErr) {

                    console.error('Error deleting file:', fileErr);
                }
            }
            res.status(204).json({ message: 'Requirement deleted successfully' });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while deleting the requirement.",
        });
    }
}

module.exports = {
    addRequirement,
    getRequirements,
    downloadTemplate,
    deleteRequirement
}
