const programsModel = require('../models/programsModel');

async function getAllPrograms(req, res) {
    try {
        const programs = await programsModel.getAllPrograms();
        res.json(programs);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching programs.",
        });
    }
}

module.exports = {
    getAllPrograms,
};