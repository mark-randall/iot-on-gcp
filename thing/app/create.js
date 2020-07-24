const mqttClient = require('./mqtt_client.js');
const deviceManagerClient = require('./device_manager_client.js');
const { exec } = require("child_process");

// Create keys
exec('../scripts/create_keys.sh', (error, stdout, stderr) => {

    if (error) {
        console.log(`error: ${error.message}`);
        return;
    }
    if (stderr) {
        console.log(`stderr: ${stderr}`);
        return;
    }
    console.log(stdout);

    const deviceName = (process.env.TEST_DEVICE_NAME !== undefined) ? process.env.TEST_DEVICE_NAME : 'unknown soldier';

    // Create device with IoT Core
    let deviceId = deviceName
    deviceManagerClient.create(deviceId).then(() => {

        // Connect to device
        mqttClient.connect(deviceId)

        // Set device state
        mqttClient.putState({
            docking: false,
            charging: false,
            running: false,
            battery: 0.5,
            mode: 1,
            firmware_version: "1.0.0"
        })
    }).catch((err) => {
        console.error(err)
    })
});

