const express = require("express");
const app = express();
const cors = require('cors')
const request = require('request').defaults({ rejectUnauthorized: false });
const log = console.log;

app.use(cors());
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST");
  res.header("Access-Control-Allow-Headers", "content-type");
  next();
});

// Proxy
app.set('trust proxy', true);

app.post("/*", async (req, res) => {
    let body = [];
    req.on('data', (chunk) => {
        body.push(chunk);
    }).on('end', async () => {
        let orgName = req.originalUrl.split('/')[1];
        url = `client.${orgName}.islab.re.kr:4000`;
        request.post({
            uri: url+req.originalUrl,
            headers: {'Content-Type': 'application/json'},
            body: body,
        })
        .pipe(res);
    });
});

app.listen(4000, () => {
  log(`API Scheduler listening on port ${4000}!`);
});
