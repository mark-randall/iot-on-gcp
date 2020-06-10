'use strict';

const iot = require('@google-cloud/iot');

const iotClient = new iot.v1.DeviceManagerClient();

exports.handler = async function(data, context, serviceLocator) {

    if (context === undefined || context.auth.uid === undefined) {
        throw new serviceLocator.functions.https.HttpsError('unauthenticated', 'Authentication required');
    }

    if (data.id === undefined) {
        throw new serviceLocator.functions.https.HttpsError('invalid-argument', 'body property "id" is required');
    }

    if (data.command === undefined) {
        throw new serviceLocator.functions.https.HttpsError('invalid-argument', 'body property "command"" is required');
    }

    // Create device path
    const name = iotClient.devicePath(
        process.env.GCLOUD_PROJECT, 
        'us-central1',
        'Robots', 
        data.id
    );

    // Convert Request data to base64
    const binaryData = Buffer.from(data.command);

    try {

        // Send command to iot client
        const iotResponse = await iotClient.sendCommandToDevice({
            name: name,
            binaryData: binaryData
        });

        // Send success response to http function
        console.error('IOT Client send command success:', iotResponse);
        return iotResponse

    } catch (err) {
        throw new serviceLocator.functions.https.HttpsError('unavailable', err);
    }
}