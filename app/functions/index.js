'use strict';

// require('@google-cloud/debug-agent').start(); // TODO: figure out why Firebase CLI can't deploy with this require
const functions = require('firebase-functions');
const admin = require('firebase-admin')

const httpsDevice = require('./https/device');
const httpsDeviceCommand = require('./https/deviceCommand');
const pubsubDeviceState = require('./pubsub/deviceState');
const firestoreDeviceConfig = require('./firestore/deviceConfig');

admin.initializeApp();

let serviceLocator = {
    admin: admin,
    functions: functions
}

// HTTPS ///////////////////////

// Accepts POST and DELETE to create and delete a IoT Core device
exports.device = functions.https.onRequest((request, response) => {
    httpsDevice.handler(request, response, serviceLocator)
});

// App callable function
// SEE: https://firebase.google.com/docs/functions/callable
exports.deviceCommand = functions.https.onCall(async (data, context) => {
    return httpsDeviceCommand.handler(data, context, serviceLocator)
});

// PUB/SUB ///////////////////////

// IoT Core default device state PubSub topic
// Published when IoT Core receives state from device
exports.pubsub_deviceStateUpdate = functions.pubsub.topic('robot-iot-state').onPublish(async (message) => {
    return pubsubDeviceState.handler(message, serviceLocator)
});

// FIRESTORE ///////////////////////

// Update and create of doc
// Updates of IoT Core devices config
exports.firestore_deviceConfigWrite = functions.firestore.document('device_configs/{deviceId}').onWrite(async (change, context) => {
    return firestoreDeviceConfig.writeHandler(change, context, serviceLocator);
});
