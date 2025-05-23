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
    const { email, role, program } = req.body;
    try{
        const accounts = await accountModel.addAccount(email, role, program);
        res.status(200).json({
            success: true,
            message: "Account added successfully.",
            data: accounts
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message || "An error occurred while fetching the accounts.",
        });
    }
}

async function updateAccount(req, res){
    const { user_id, email, role, program, status } = req.body;
    try{
        const accounts = await accountModel.updateAccount(user_id, email, role, program, status);
        res.status(200).json({
            success: true,
            message: "Account updated successfully.",
            data: accounts
        });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while updating the account.",
        });
    }
}

async function deleteAccount(req, res){
    const { email } = req.params;
    try{
        const accounts = await accountModel.deleteAccount(email);
        res.status(200).json({
            success: true,
            message: "Account archived successfully.",
            data: accounts
        });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the accounts.",
        });
    }
}

async function unarchiveAccount(req, res){
    const { user_id } = req.params;
    try{
        const accounts = await accountModel.unarchiveAccount(user_id);
        res.status(200).json({
            success: true,
            message: "Account unarchived successfully.",
            data: accounts
        });
    } catch (error) {
        res.status(500).json({
            error: error.message || "An error occurred while fetching the accounts.",
        });
    }
}

module.exports = {
    getAccounts,
    addAccount,
    updateAccount,
    deleteAccount,
    unarchiveAccount
};