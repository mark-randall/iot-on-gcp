'use strict';

const iot = require('@google-cloud/iot');

const client = new iot.v1.DeviceManagerClient();

exports.writeHandler = async function(change, context, serviceLocator) {

    if (!context) {
        console.error('no context found');
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
        const binaryData = Buffer.from(JSON.stringify(change.after.data())).toString('base64');

        return client.modifyCloudToDeviceConfig({
            name: name,
            binaryData: binaryData
        });
    } 

    // Update BigQuery?
    // TODO
};