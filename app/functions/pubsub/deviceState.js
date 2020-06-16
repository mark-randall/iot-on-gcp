'use strict';

const { Firestore } = require('@google-cloud/firestore');
const { Logging } = require('@google-cloud/logging');

const firestore = new Firestore();
const loggingClient = new Logging({
    projectId: process.env.GCLOUD_PROJECT,
});

exports.handler = async function(message, serviceLocator) {

    // Log pub/sub payload to Stackdriver for device id and number
    const log = loggingClient.log('device-state');
    const metadata = {
        resource: {
            type: 'cloudiot_device',
            labels: {
                project_id: message.attributes.projectId,
                device_num_id: message.attributes.deviceNumId,
                device_registry_id: message.attributes.deviceRegistryId,
                location: message.attributes.location,
            }
        },
        labels: {
            device_id: message.attributes.deviceId,
        }
    };
    const entry = log.entry(metadata, message.json);
    log.write(entry);

    // Update firestore for device
    const deviceDocument = firestore.doc(`devices/${message.attributes.deviceId}`);

    try {
        await deviceDocument.update({
            state: message.json
        });
        console.log(`State updated for ${message.attributes.deviceId}`);
        return true
    } catch (err) {
        console.error(err);
        return false
    }
};