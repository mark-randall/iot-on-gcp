'use strict';

const { Firestore } = require('@google-cloud/firestore');

const firestore = new Firestore();

exports.handler = async function(message, serviceLocator) {

    // Update firestore for device
    const deviceId = message.attributes.deviceId;
    const deviceDocument = firestore.doc(`devices/${deviceId}`);

    try {
        await deviceDocument.update({
            state: message.json
        });
        console.log(`State updated for ${deviceId}`);
        return true
    } catch (err) {
        console.error(err);
        return false
    }

    // Update BigQuery
    // TODO
};