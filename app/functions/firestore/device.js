'use strict';

const iot = require('@google-cloud/iot');

const client = new iot.v1.DeviceManagerClient();

exports.updateHandler = async function(change, context, serviceLocator) {

    if (!context) {
        console.error('no context found');
    } else if (change.after.data()['config'] === undefined) {
        console.error('change after.data is missing config map');
    } else {

        console.log(`Updating device (${context.params.deviceId}) config from Firestore`);

        // Create device path
        const name = client.devicePath(
            process.env.GCLOUD_PROJECT, 
            'us-central1',
            'Robots', 
            context.params.deviceId
        );

        // Convert Firestore data to base64
        const binaryData = Buffer.from(JSON.stringify(change.after.data()['config'])).toString('base64');

        return client.modifyCloudToDeviceConfig({
            name: name,
            binaryData: binaryData
        });
    } 

    // Update BigQuery?
    // TODO
};