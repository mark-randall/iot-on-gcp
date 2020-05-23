'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin')

const httpsRobots = require('./https/robots');

admin.initializeApp();

// Create robot VM
exports.robots = functions.https.onRequest((request, response) => {
    httpsRobots.handler(request, response, admin)
});
