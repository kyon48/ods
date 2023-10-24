'use strict';

const { Wallets } = require('fabric-network');
const FabricCAServices = require('fabric-ca-client');

const fs = require('fs');
const path = require('path');

const ccpPath = path.resolve(__dirname, '../connection-profile.json');
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);

const getFabricCAUrl = async (orgName) => {
    let result = null;
    Object.keys(ccp.certificateAuthorities).forEach((key) => {
        if(key.includes(orgName)) {
            result = ccp.certificateAuthorities[key];
        }
    });

    if(result === null) {
        throw new Error('is not valid orgName');
    } else {
        return result;
    }
}

module.exports.enrollAdmin = async (orgName, adminID, adminPassword) => {
    try {
        const caInfo = await getFabricCAUrl(orgName);
        const caTLSCACerts = fs.readFileSync(caInfo.tlsCACerts.path);
        const ca = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false }, caInfo.caName);

        const walletPath = path.join(__dirname, '../wallet', orgName);
        const wallet = await Wallets.newFileSystemWallet(walletPath);

        const userIdentity = await wallet.get(adminID);
        if (userIdentity) {
            throw new Error(`${adminID} is already exists in ${orgName}'s wallet`);
        }

        const enrollment = await ca.enroll({
            enrollmentID: adminID,
            enrollmentSecret: adminPassword
        });

        const x509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId: `${orgName}MSP`,
            type: 'X.509',
        };

        await wallet.put(adminID, x509Identity);
        console.log(`Successfully registered and enrolled ${adminID} and imported it into the wallet`);
    } catch (error) {
        throw new Error(error);
    }
}

module.exports.enrollUser = async (orgName, userID, userPassword) => {
    try {
        const caInfo = await getFabricCAUrl(orgName);
        const caTLSCACerts = fs.readFileSync(caInfo.tlsCACerts.path);
        const ca = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false }, caInfo.caName);

        const walletPath = path.join(__dirname, '../wallet', orgName);
        const wallet = await Wallets.newFileSystemWallet(walletPath);

        const userIdentity = await wallet.get(userID);
        if (userIdentity) {
            throw new Error(`${userID} is already exists in ${orgName}'s wallet`);
        }

        const adminIdentity = await wallet.get('admin');
        if (!adminIdentity) {
            throw new Error(`admin is not exist in ${orgName}'s wallet`);
        }

        const provider = wallet.getProviderRegistry().getProvider(adminIdentity.type);
        const adminUser = await provider.getUserContext(adminIdentity, 'admin');

        await ca.register({
            enrollmentID: userID,
            enrollmentSecret: userPassword,
            role: 'client'
        }, adminUser);

        const enrollment = await ca.enroll({
            enrollmentID: userID,
            enrollmentSecret: userPassword
        });

        const x509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId: `${orgName}MSP`,
            type: 'X.509',
        };

        await wallet.put(userID, x509Identity);
        console.log(`Successfully registered and enrolled ${userID} and imported it into the wallet`);
    } catch (error) {
        throw new Error(error);
    }
}

module.exports.reEnrollUser = async (orgName, userID) => {
    try {
        const caInfo = await getFabricCAUrl(orgName);
        const caTLSCACerts = fs.readFileSync(caInfo.tlsCACerts.path);
        const ca = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false }, caInfo.caName);

        const walletPath = path.join(__dirname, '../wallet', orgName);
        const wallet = await Wallets.newFileSystemWallet(walletPath);

        const userIdentity = await wallet.get(userID);
        if (!userIdentity) {
            throw new Error(`${userID} is not exist in ${orgName}'s wallet`);
        }

        const provider = wallet.getProviderRegistry().getProvider(userIdentity.type);
        const user = await provider.getUserContext(userIdentity, userID);

        const enrollment = await ca.reenroll(user);

        const x509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId: `${orgName}MSP`,
            type: 'X.509',
        };

        await wallet.put(userID, x509Identity);
        console.log(`Successfully reenrolled ${userID} and imported it into the wallet`);
    } catch (error) {
        throw new Error(error);
    }
}

module.exports.revokeUser = async (orgName, userID) => {
    try {
        const caInfo = await getFabricCAUrl(orgName);
        const caTLSCACerts = fs.readFileSync(caInfo.tlsCACerts.path);
        const ca = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false }, caInfo.caName);

        const walletPath = path.join(__dirname, '../wallet', orgName);
        const wallet = await Wallets.newFileSystemWallet(walletPath);

        const userIdentity = await wallet.get(userID);
        if (!userIdentity) {
            throw new Error(`${userID} is not exist in ${orgName}'s wallet`);
        }

        const provider = wallet.getProviderRegistry().getProvider(userIdentity.type);
        const user = await provider.getUserContext(userIdentity, userID);

        await ca.revoke({ enrollmentID: userID }, user);

        await wallet.remove(userID);
        console.log(`Successfully revoked ${userID} and deleted it into the wallet`);
    } catch (error) {
        throw new Error(error);
    }
}