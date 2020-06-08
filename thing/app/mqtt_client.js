const fs = require('fs');
const jwt = require('jsonwebtoken');
const mqtt = require('mqtt');

let mqttClient = null
let deviceId = null

// Cached config
let state = {
    docking: false,
	charging: false,
	running: false,
	battery: 0.5,
    mode: 1,
    firmware_version: '1.0.0'
}

/// Connect to device state /////////////////////////////////////////////////////

// MQTT password JWT
//
// Returns JWT 
//
const passwordJwt = (projectId, privateKeyFile, algorithm) => {

    const token = {
        iat: parseInt(Date.now() / 1000),
        exp: parseInt(Date.now() / 1000) + 20 * 60, // 20 minutes
        aud: projectId,
    };
    
    const privateKey = fs.readFileSync(privateKeyFile);
    return jwt.sign(token, privateKey, {algorithm: algorithm});
};

// MQTT connection arguments
//
// Uses:
// * passwordJwt to create MQTT password
//
// Returns MQTT connection arguments
//
const connectionArguments = (deviceId) => {

    const projectId = 'robots-277919'
    const registryId = `Robots`;
    const region = `us-central1`;
    const algorithm = `RS256`;
    const privateKeyFile = `rsa_private.pem`;
    const mqttBridgeHostname = `mqtt.googleapis.com`;
    const mqttBridgePort = 8883;

    // MQTT path
    const mqttClientId = `projects/${projectId}/locations/${region}/registries/${registryId}/devices/${deviceId}`;

    // Create JWT
    const password = passwordJwt(projectId, privateKeyFile, algorithm)

    return {
        host: mqttBridgeHostname,
        port: mqttBridgePort,
        clientId: mqttClientId,
        username: 'unused', // IoT Core doesn't use this MQTT field
        password: password,
        protocol: 'mqtts',
        secureProtocol: 'TLSv1_2_method',
        reconnectPeriod: 1000 * 3,
        clean: false
    }
}

// Connect to device with MQTT
//
// Uses: 
// * connectionArgument - as MQTT connection arguments
//
// Side-effects:
// * Sets this.deviceId
// * Calls updateStateForConfig for config topic messages
// * Calls updateStateForCommand for commands/# topic messages
//
function connect(id) {
    deviceId = id

    // Connect
    mqttClient = mqtt.connect(connectionArguments(deviceId));

    // Subscribe to topics
    mqttClient.subscribe('/devices/' + deviceId + '/config', {qos: 1});
    mqttClient.subscribe('/devices/' + deviceId + '/commands/#', {qos: 0});

    mqttClient.on('connect', success => {
        if (success === false) {
            console.log('MQTT client not connected');
        } else { 
            console.log('MQTT client connected')
        }
    });

    mqttClient.on('close', () => {
        console.log('MQTT client close');
    });

    mqttClient.on('error', err => {
        console.log('MQTT client error', err);
    });

    mqttClient.on('message', (topic, message) => {
        console.log('MQTT ' + topic + ' message received')

        let topicString = Buffer.from(message, 'base64').toString('ascii');
        if (topicString.length > 0) {
            let topicState = JSON.parse(topicString)

            if (topic === '/devices/' + deviceId + '/config') {
                updateStateForConfig(topicState)
            } else {
                handleCommand(topicString, topicState)
            }
        } else {
            console.log('Message is empty')
        }
    });
}

function getState() {
    return state;
}

/// Update device state /////////////////////////////////////////////////////

// Modify device state
function patchState(patch) {
    let message = Object.assign(state, patch);
    publishMessage('/devices/' + deviceId + '/state', JSON.stringify(message))
}

// Update device state
function putState(message) {
    publishMessage('/devices/' + deviceId + '/state', JSON.stringify(message))
}

// Publish a message @ topic to MQTT client
function publishMessage(topic, message) {
    console.log(`MQTT publishing to ${topic}: ${message}`);

    mqttClient.publish(topic, message, {qos: 1}, err => {
        if (err) {
            console.log(err)
        } else {
            console.log('MQTT message sent')
        }
    });
}

/// Thing logic /////////////////////////////////////////////////////

// Update state based on command messages received
function updateStateForCommand(topic, message) {
    if (topic === 'running_mode') {
        console.log('MQTT TODO handle running_mode update')
    } else {
        console.error('MQTT command topic not supported')
    }
}

// Update state based on config messages received
function updateStateForConfig(config) {
    if (config.mode !== undefined) {
        state.mode = config.mode
    }

    putState(state)
}

/// Module exports /////////////////////////////////////////////////////

exports.connect = connect
exports.getState = getState
exports.patchState = patchState
exports.putState = putState
