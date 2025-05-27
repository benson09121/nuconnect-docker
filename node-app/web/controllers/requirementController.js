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

async function updateRequirement(req, res) {
    const { requirement_name, requirement_id, template_name } = req.body;
    try {
        // Get the current requirement to find the old file if needed
        const [requirement] = await requirementModel.getSpecificRequirement(requirement_id);
        if (!requirement) {
            return res.status(404).json({ message: 'Requirement not found' });
        }

        let newFileName = requirement.file_path;

        if (!req.files || !req.files.template) {
            // No new file uploaded, just update the name
            await requirementModel.updateRequirement(requirement_id, requirement_name, newFileName);
            return res.status(200).json({ message: 'Requirement updated successfully' });
        } else {
            // New file uploaded: delete old file, save new file, update DB
            const uploadedFile = req.files.template;

            // Delete old file
            if (requirement.file_path) {
                const oldFilePath = path.join('/app/requirements', requirement.file_path);
                try {
                    if (fs.existsSync(oldFilePath)) {
                        fs.unlinkSync(oldFilePath);
                    }
                } catch (fileErr) {
                    console.error('Error deleting old file:', fileErr);
                }
            }

            // Save new file
            const filename = `requirement-${Date.now()}-${uploadedFile.name}`;
            const savePath = path.join('/app/requirements', filename);
            try {
                fs.writeFileSync(savePath, uploadedFile.data);
            } catch (writeError) {
                return res.status(500).json({ message: 'Error saving file', error: writeError.message });
            }

            newFileName = filename;
            await requirementModel.updateRequirement(requirement_id, requirement_name, newFileName);
            return res.status(200).json({ message: 'Requirement and file updated successfully' });
        }
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while updating the requirement.",
        });
    }
}

 async function addApplicationPeriod(req, res) {
           const { startDate, endDate, startTime, endTime } = req.body;
    try {
 
        if (!startDate || !endDate) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        await requirementModel.addApplicationPeriod( startDate, endDate, startTime, endTime, req.user.user_id );
        res.status(201).json({ message: 'Requirement period added successfully' });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while adding the requirement period.",
        });
    }
}

async function getActiveApplicationPeriod(req, res) {
    try {
        const activePeriod = await requirementModel.getActiveApplicationPeriod();
        if (activePeriod.length === 0) {
            return res.status(404).json({ message: 'No active application period found' });
        }
        res.json(activePeriod);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the active application period.",
        });
    }
}

async function updateApplicationPeriod(req, res) {
    const { startDate, endDate, startTime, endTime, period_id } = req.body;
    try {
        await requirementModel.updateApplicationPeriod( startDate, endDate, startTime, endTime, period_id);
        res.status(200).json({ message: 'Requirement period updated successfully' });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while updating the requirement period.",
        });
    }
}

module.exports = {
    addRequirement,
    getRequirements,
    downloadTemplate,
    deleteRequirement,
    updateRequirement,
    addApplicationPeriod,
    getActiveApplicationPeriod,
    updateApplicationPeriod
}
