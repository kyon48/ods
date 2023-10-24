var express = require('express');
var router = express.Router();
var FabricChaincodeQuery = require('../sdk/chaincodeQuery');
var FabricChaincodeInvoke = require('../sdk/chaincodeInvoke');
var moment = require("moment");

router.post('/CreateAsset', async (req, res) => {
  const orgName = req.body.orgName;
  const channelName = req.body.channelName;
  const chaincodeName = req.body.chaincodeName;

  const reqParam = req.body.param;

  try {
    const result = await FabricChaincodeInvoke.invoke(
      orgName,
      channelName,
      chaincodeName,
      "CreateAsset",
      reqParam.id,
      reqParam.color,
      reqParam.owner,
      reqParam.size,
      reqParam.appraisedValue
    );
      resultString = result.toString();
      console.log(resultString);
      res.status(200).send({ "message": resultString });
  } catch (error) {
      console.log(error);
      res.status(500);
      res.send({ "message": error.toString(), "param": reqParam });
  }
});

router.post('/ReadAsset', async (req, res) => {
  const orgName = req.body.orgName;
  const channelName = req.body.channelName;
  const chaincodeName = req.body.chaincodeName;

  const reqParam = req.body.param;

  try {
    const result = await FabricChaincodeQuery.query(
      orgName,
      channelName,
      chaincodeName,
      "ReadAsset",
      reqParam.id
    );
      resultString = result.toString();
      console.log(resultString);
      res.status(200).send({ "message": resultString });
  } catch (error) {
      console.log(error);
      res.status(500);
      res.send({ "message": error.toString(), });
  }
});

router.post('/UpdateAsset', async (req, res) => {
  const orgName = req.body.orgName;
  const channelName = req.body.channelName;
  const chaincodeName = req.body.chaincodeName;

  const reqParam = req.body.param;

  try {
    const result = await FabricChaincodeInvoke.invoke(
      orgName,
      channelName,
      chaincodeName,
      "UpdateAsset",
      reqParam.id,
      reqParam.color,
      reqParam.owner,
      reqParam.size,
      reqParam.appraisedValue
    );
      resultString = result.toString();
      console.log(resultString);
      res.status(200).send({ "message": resultString });
  } catch (error) {
      console.log(error);
      res.status(500);
      res.send({ "message": error.toString(), "param": reqParam });
  }
});

router.post('/DeleteAsset', async (req, res) => {
  const orgName = req.body.orgName;
  const channelName = req.body.channelName;
  const chaincodeName = req.body.chaincodeName;

  const reqParam = req.body.param;

  try {
    const result = await FabricChaincodeInvoke.invoke(
      orgName,
      channelName,
      chaincodeName,
      "DeleteAsset",
      reqParam.id
    );
      resultString = result.toString();
      console.log(resultString);
      res.status(200).send({ "message": resultString });
  } catch (error) {
      console.log(error);
      res.status(500);
      res.send({ "message": error.toString(), "param": reqParam });
  }
});

router.post('/AssetExists', async (req, res) => {
  const orgName = req.body.orgName;
  const channelName = req.body.channelName;
  const chaincodeName = req.body.chaincodeName;

  const reqParam = req.body.param;

  try {
    const result = await FabricChaincodeQuery.query(
      orgName,
      channelName,
      chaincodeName,
      "AssetExists",
      reqParam.id
    );
      resultString = result.toString();
      console.log(resultString);
      res.status(200).send({ "message": resultString });
  } catch (error) {
      console.log(error);
      res.status(500);
      res.send({ "message": error.toString(), "param": reqParam });
  }
});

router.post('/TransferAsset', async (req, res) => {
  const orgName = req.body.orgName;
  const channelName = req.body.channelName;
  const chaincodeName = req.body.chaincodeName;

  const reqParam = req.body.param;

  try {
    const result = await FabricChaincodeInvoke.invoke(
      orgName,
      channelName,
      chaincodeName,
      "TransferAsset",
      reqParam.id,
      reqParam.newOwner
    );
      resultString = result.toString();
      console.log(resultString);
      res.status(200).send({ "message": resultString });
  } catch (error) {
      console.log(error);
      res.status(500);
      res.send({ "message": error.toString(), "param": reqParam });
  }
});

router.post('/GetAllAssets', async (req, res) => {
  const orgName = req.body.orgName;
  const channelName = req.body.channelName;
  const chaincodeName = req.body.chaincodeName;

  try {
    const result = await FabricChaincodeQuery.query(
      orgName,
      channelName,
      chaincodeName,
      "GetAllAssets"
    );
      resultString = result.toString();
      console.log(resultString);
      res.status(200).send({ "message": resultString });
  } catch (error) {
      console.log(error);
      res.status(500);
      res.send({ "message": error.toString() });
  }
});

module.exports = router;