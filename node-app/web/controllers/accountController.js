const msal = require('@azure/msal-node');
const axios = require('axios');
const accountModel = require('../models/accountModel');

async function getAccounts(req, res){
    try{
        const accounts = await accountModel.getAccounts();
        res.status(200).json(accounts);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the accounts.",
        });
    }
    
}

async function addAccount(req, res){
    const { email, name, role, program } = req.body;
    const f_name = name.split(" ")[0];
    const l_name = name.split(" ")[1];
    try{
        const accounts = await accountModel.addAccount(email, role, program, f_name, l_name);
        res.status(200).json(accounts);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the accounts.",
        });
    }
    
}

async function deleteAccount(req, res){
    const { email } = req.params;
    try{
        const accounts = await accountModel.deleteAccount(email);
        res.status(200).json(accounts);
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the accounts.",
        });
    }
}

module.exports = {
    getAccounts,
    addAccount,
    deleteAccount
};