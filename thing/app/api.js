const express = require('express');

const app = express();
app.use(express.json());

let mqttClient = null

app.get('/state', (req, res) => {
    res.send(this.mqttClient.getState());
});

app.patch('/state', (req, res) => {
    this.mqttClient.patchState(req.body)
    res.send({});
});

app.put('/state', (req, res) => {
    this.mqttClient.putState(req.body)
    res.send({});
});

// Start API
function start(mqttClient) {
    this.mqttClient = mqttClient

    // Start Express server
    const server = app.listen(8080, () => {
        const host = server.address().address;
        const port = server.address().port;
        console.log('API listening at http://' + host + ':' + port);
    });
}

exports.start = start