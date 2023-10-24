const express = require('express');
const app = express();
const cors = require('cors')
const bodyParser = require('body-parser');
const routes = require('./routes');
const { logger } = require('./utils/logger');
const swaggerExtensionJson = require('./routes/chaincode-swagger.json');
const swaggerUi = require('swagger-ui-express');

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST");
  res.header("Access-Control-Allow-Headers", "content-type");
  next();
});

app.use('/chaincode', routes.chaincode);
app.use('/user', routes.user);

app.get('/swagger.json', (req, res) => {
  res.json(swaggerExtensionJson);
});
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerExtensionJson));

// Server Start
app.listen(process.env.FABRIC_CLIENT_PEER_API_PORT, () => {
  logger.info(`API Server listening on port ${process.env.FABRIC_CLIENT_PEER_API_PORT}!`);
});