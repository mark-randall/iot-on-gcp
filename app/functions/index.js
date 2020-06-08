'use strict';

// require('@google-cloud/debug-agent').start(); // TODO: figure out why Firebase CLI can't deploy with this require
const functions = require('firebase-functions');
const admin = require('firebase-admin')

const httpsDevice = require('./https/device');
const pubsubDeviceState = require('./pubsub/deviceState');
const firestoreDevice = require('./firestore/device');

admin.initializeApp();

let serviceLocator = {
    admin: admin,
    functions: functions
}

// HTTPS ///////////////////////

// Accepts POST and DELETE to create and delete a IoT Core device
exports.robots = functions.https.onRequest((request, response) => {
    httpsDevice.handler(request, response, serviceLocator)
});

// PUB/SUB ///////////////////////

// IoT Core default device state PubSub topic
// Published when IoT Core receives state from device
exports.pubsub_deviceStateUpdate = functions.pubsub.topic('robot-iot-state').onPublish(async (message) => {
    return pubsubDeviceState.handler(message, serviceLocator)
});

// FIRESTORE ///////////////////////

// Document represent an IoT device
// Updates Devices config based on docs config property
exports.firestore_deviceUpdate = functions.firestore.document('devices/{deviceId}').onUpdate(async (change, context) => {
    return firestoreDevice.updateHandler(change, context, serviceLocator);
});

// Handles device document creation
exports.firestore_deviceCreate = functions.firestore.document('devices/{deviceId}').onCreate(async (change, context) => {
    return firestoreDevice.updateHandler(change, context, serviceLocator);
});
