const mqttClient = require('./mqtt_client.js');
const api = require('./api.js');

// Connect to device with id 'test'
mqttClient.connect('test')

// Start API
api.start(mqttClient)