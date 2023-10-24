'use strict';

const { Wallets, Gateway } = require('fabric-network');

const fs = require('fs');
const path = require('path');

let contract = null;

module.exports.InitContract = async (orgName, ch, cc) => {
    const ccpPath = path.resolve(__dirname, `../connection-profile.json`);
    const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
    const ccp = JSON.parse(ccpJSON);
    
    const walletPath = path.join(__dirname, '../wallet', orgName);
    const wallet = await Wallets.newFileSystemWallet(walletPath);
    const gateway = new Gateway();
    const opts = {
        wallet,
        identity: 'admin',
        discovery: {enabled: true, asLocalhost: false}
    };
    await gateway.connect(ccp, opts);
    const network = await gateway.getNetwork(ch);
    contract = network.getContract(cc);
}

module.exports.query = async (orgName, ch, cc, ...params) => {
    if (typeof params == "string" ) {
        try {
            if (contract == null) {
                await this.InitContract(orgName, ch, cc);
            }
            const result = await contract.submitTransaction(params);
            return result;
        } catch (error) {
            throw new Error(error);
        }
    } else {
        try {
            if (contract == null) {
                await this.InitContract(orgName, ch, cc);
            }
            console.log(...params)
            const result = await contract.submitTransaction(...params);
            return result;
        } catch (error) {
            throw new Error(error);
        }
    }
}
