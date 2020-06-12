'use strict';

const iot = require('@google-cloud/iot');

const iotClient = new iot.v1.DeviceManagerClient();

// Call handler
exports.callHandler = async function(data, context, serviceLocator) {

    if (context === undefined || context.auth.uid === undefined) {
        throw new serviceLocator.functions.https.HttpsError('unauthenticated', 'Authentication required');
    }

    if (data.id === undefined) {
        throw new serviceLocator.functions.https.HttpsError('invalid-argument', 'body property "id" is required');
    }

    if (data.command === undefined) {
        throw new serviceLocator.functions.https.HttpsError('invalid-argument', 'body property "command"" is required');
    }

    try {
        return await sendCommand(data.id, data.command, serviceLocator)
    } catch (err) {
        throw new serviceLocator.functions.https.HttpsError('unavailable', err);
    }
};

// HTTP handler
exports.handler = async function(request, response, serviceLocator) {

    // Authorization
    // TODO: Currently on SA supported

    // Handle method
    switch (request.method.toLowerCase()) {
        case 'post':
            return create(request,response, serviceLocator);
        default:
            response.status(405).send({'success': false, 'result': request.method + ' not supported'});
            break;
    } 
};

// HTTP POST
async function create(request, response, serviceLocator) {

    if (request.body.id === undefined) {
        console.log('body property "id" is required')
        response.status(400).send('body property "id" is required');
        return;
    }

    if (request.body.command === undefined) {
        console.log('body property "command" is required')
        response.status(400).send('body property "command" is required');
        return;
    }

    try {
        const sendCommandResponse = await sendCommand(request.body.id, request.body.command, serviceLocator)

        // Delete scheduling Firestore document if used
        if (request.body.scheduler_id !== undefined) {

            return serviceLocator.admin.firestore().doc(`device_configs/${request.body.id}/schedule/${request.body.scheduler_id}`).delete().then(() => {
                return response.send(sendCommandResponse);
            }).catch((err) => {
                return response.status(409).send({error: err});
            });
        } else {
            return response.send(sendCommandResponse);
        }
    } catch (err) {
        response.status(409).send({error: err});
    }
}

// HTTP POST
async function sendCommand(deviceId, command, serviceLocator) {

    // Create device path
    const name = iotClient.devicePath(
        process.env.GCLOUD_PROJECT, 
        'us-central1',
        'Robots', 
        deviceId
    );

    // Convert Request data to base64
    const binaryData = Buffer.from(JSON.stringify(command)).toString('base64');

    console.log(`Sending command ${command} to ${deviceId}`)

    // Send command to iot client
    const iotResponse = await iotClient.sendCommandToDevice({
        name: name,
        binaryData: binaryData
    });

    // Send success response to http function
    console.log('IOT Client send command success:', iotResponse);

    return iotResponse
}