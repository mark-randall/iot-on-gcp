const iot = require('@google-cloud/iot');
const fs = require('fs');

const deviceManagerClient = new iot.v1.DeviceManagerClient();

// Register device
async function create(deviceId) {

    const projectId = 'robots-277919'
    const registryId = 'Robots';
    const privateKeyFile = 'rsa_cert.pem';
    const region = 'us-central1';

    const device = {
        id: deviceId,
        credentials: [
            {
                publicKey: {
                    format: 'RSA_X509_PEM',
                    key: fs.readFileSync(privateKeyFile).toString(),
                },
            }
        ]
    }

    const request = {
        parent: deviceManagerClient.registryPath(projectId, region, registryId),
        device,
    }

    try {
        const responses = await deviceManagerClient.createDevice(request);
        const response = responses[0];
        console.log('Created device', response);
    } catch (err) {
        console.error('Could not create device', err);
    }
}

exports.create = create