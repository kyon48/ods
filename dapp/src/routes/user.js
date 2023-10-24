var express = require('express');
var router = express.Router();
var FabricUser = require('../sdk/user');

router.post('/enrollAdmin', async (req, res) => {
    const orgName = req.body.orgName;
    const adminId = req.body.adminId;
    const adminPassword = req.body.adminPassword;
    console.log(`[POST user/enrollAdmin ${adminId}]`);

    try {
        await FabricUser.enrollAdmin(orgName, adminId, adminPassword);
        res.status(200).send(`Successfully registered and enrolled ${adminId}`);
    } catch (error) {
        console.log(error);
        res.status(500).send('enroll failed');
    }
});

router.post('/enroll', async (req, res) => {
    const orgName = req.body.orgName;
    const userId = req.body.userId;
    const userPassword = req.body.userPassword;
    console.log(`[POST user/enroll ${userId}]`);

    try {
        await FabricUser.enrollUser(orgName, userId, userPassword);
        res.status(200).send(`Successfully registered and enrolled ${userId}`);
    } catch (error) {
        console.log(error);
        res.status(500).send('enroll failed');
    }
});

router.post('/reenroll', async (req, res) => {
    const orgName = req.body.orgName;
    const userId = req.body.userId;
    console.log(`[POST user/reenroll ${userId}]`);

    try {
        await FabricUser.reEnrollUser(orgName, userId);
        res.status(200).send(`Successfully reenrolled ${userId}`);
    } catch (error) {
        console.log(error);
        res.status(500).send('reenroll failed');
    }
});

router.post('/revoke', async (req, res) => {
    const orgName = req.body.orgName;
    const userId = req.body.userId;
    console.log(`[POST user/revoke ${userId}]`);

    try {
        await FabricUser.revokeUser(orgName, userId);
        res.status(200).send(`Successfully revoke ${userId}`);
    } catch (error) {
        console.log(error);
        res.status(500).send('revoke failed');
    }
});

module.exports = router;