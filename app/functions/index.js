'use strict';

// require('@google-cloud/debug-agent').start(); // TODO: figure out why Firebase CLI can't deploy with this require
const functions = require('firebase-functions');
const admin = require('firebase-admin')

const httpsDevice = require('./https/device');
const httpsDeviceCommand = require('./https/deviceCommand');
const pubsubDeviceState = require('./pubsub/deviceState');
const firestoreDeviceConfig = require('./firestore/deviceConfig');
const firestoreDeviceSchedule = require('./firestore/deviceSchedule');

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

// App callable function to send command to device
// SEE: https://firebase.google.com/docs/functions/callable
exports.callable_deviceCommand = functions.https.onCall(async (data, context) => {
    return httpsDeviceCommand.callHandler(data, context, serviceLocator)
});

// Accepts POST to send command to device
// Called by Cloud Tasks created by firestore_deviceScheduleWrite
exports.deviceCommand = functions.https.onRequest((request, response) => {
    return httpsDeviceCommand.handler(request, response, serviceLocator)
});


// PUB/SUB ///////////////////////

// IoT Core default device state PubSub topic
// Published when IoT Core receives state from device
// Updates Firestore device/id doc
exports.pubsub_deviceStateUpdate = functions.pubsub.topic('robot-iot-state').onPublish(async (message) => {
    return pubsubDeviceState.handler(message, serviceLocator)
});

// FIRESTORE ///////////////////////

// Used to update IoT Core devices config
// Using onWrite because document will not be deleted
exports.firestore_deviceConfigWrite = functions.firestore.document('device_configs/{deviceId}').onWrite(async (change, context) => {
    return firestoreDeviceConfig.writeHandler(change, context, serviceLocator);
});

// Device schedule create
exports.firestore_deviceScheduleCreate = functions.firestore.document('device_configs/{deviceId}/schedule/{scheduleId}').onCreate(async (snapshot, context) => {
    return firestoreDeviceSchedule.createHandler(snapshot, context, serviceLocator);
});

// Deivce schedule delete
// Deletes Cloud Tasks task for schedule
exports.firestore_deviceScheduleDelete = functions.firestore.document('device_configs/{deviceId}/schedule/{scheduleId}').onDelete(async (snapshot, context) => {
    return firestoreDeviceSchedule.deleteHandler(snapshot, context, serviceLocator);
});
