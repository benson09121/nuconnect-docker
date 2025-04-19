const organizationModel = require('../models/organizationModel'); 



async function getOrganizations(req, res) {
    try {
        const organizations = await organizationModel.getOrganizations();
        res.json(organizations);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

async function getUserOrganization(req, res) {
    try {
        const userOrganization = await organizationModel.getUserOrganization();
        res.json(userOrganization);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}

module.exports = {
    getOrganizations,
    getUserOrganization
}
