const fs = require('fs');
const jwt = require('jsonwebtoken');
const mqtt = require('mqtt');

let mqttClient
let deviceId

// State of device on start up
let defaultState = {
    docking: false,
	charging: false,
	running: false,
	battery: 0.5,
    mode: "1",
    firmware_version: '1.0.0'
}

// Current state of device
let state

const statePublishThrottle = 1500
let lastPublishedStateCompleted = new Date(0)
let isPublishStatePending = false
let pendingStatePublish

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

    mqttClient.on('connect', success => {
        if (success === false) {
            console.log('MQTT client not connected');
        } else { 
            console.log('MQTT client connected')

            putState(defaultState)

            // Subscribe to topics
            mqttClient.subscribe('/devices/' + deviceId + '/config', {qos: 1});
            mqttClient.subscribe('/devices/' + deviceId + '/commands/#', {qos: 0});
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

            if (topic === `/devices/${deviceId}/config`) {
                updateStateForConfig(topicState)
            } else {
                updateStateForCommand(topic, topicState)
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
    let message = Object.assign(patch, state);
    putState(message)
}

// Update device state
function putState(message) {
    publishMessage('/devices/' + deviceId + '/state', JSON.stringify(message))
    state = message
}

// Publish a message @ topic to MQTT client
function publishMessage(topic, message) {

    console.log(`MQTT checking if publish is available for ${topic}`);

    if (topic === '/devices/' + deviceId + '/state') {

        // Check if state publish is in progress
        if (isPublishStatePending === true) {
            pendingStatePublish = message
            console.log("MQTT publish in progress waiting for completion")
            return;
        }

        // Check if state was pubished less than maxRequestRate
        let now = new Date()
        let nextWindow = new Date(lastPublishedStateCompleted.getTime() + statePublishThrottle)
        if (now.getTime() < nextWindow.getTime()) {
            
            setTimeout(function() {
                publishMessage(topic, message)
            }, nextWindow.getTime() - now.getTime());
            console.log("MQTT publish being throttled");
            return;
        }

        isPublishStatePending = true
    }

    console.log(`MQTT attempting to publish to ${topic}: ${message}`);

    mqttClient.publish(topic, message, {qos: 1}, err => {

        if (err) {
            console.log(`MQTT message publish failed: ${err}`)
        } else {
            console.log('MQTT message published')
        }

        lastPublishedStateCompleted = new Date()
        isPublishStatePending = false

        if (pendingStatePublish !== undefined) {
            publishMessage('/devices/' + deviceId + '/state', pendingStatePublish)
        }

        pendingStatePublish = undefined
    });
}

/// Thing logic /////////////////////////////////////////////////////

// Update state based on command messages received
function updateStateForCommand(topic, message) {

    if (topic === `/devices/${deviceId}/commands`) {
        
        if (message.type === 'running_state') {

            if (message.value === 'start') {
                let update = Object.assign(state, {running: true});
                putState(update)
            } else if (message.value === 'stop') {
                let update = Object.assign(state, {running: false}, );
                putState(update)
            } else {
                console.log(`MQTT command topic ${topic} message not properly formed. "value" value not recognized`)
            }
        } else {
            console.log(`MQTT command topic ${topic} message not properly formed. "type" value not recognized`)
        }
    } else {
        console.log('MQTT command topic not supported')
    }
}

// Update state based on config messages received
function updateStateForConfig(config) {
    if (config.mode !== undefined) {
        let update = Object.assign(state, {mode: config.mode});
        putState(update)
    }
}

/// Module exports /////////////////////////////////////////////////////

exports.connect = connect
exports.getState = getState
exports.patchState = patchState
exports.putState = putState
