'use strict';

const { CloudTasksClient } = require('@google-cloud/tasks');

const cloudTasksClient = new CloudTasksClient();

// Create Task queue path
const project = 'robots-277919';
const queue = 'device-scheduled-run-queue';
const location = 'us-central1';
const parent = cloudTasksClient.queuePath(project, location, queue);

exports.createHandler = async function(snapshot, context, serviceLocator) {

    if (!context) {
        console.error('No context found');
    } else {
        console.log(`Create cloud teasks for ${context.params.deviceId} schedule ${context.params.scheduleId} from Firestore`);

        // Validate document
        if (snapshot.data()['time'] === undefined) {
            console.log('document property "time" is required');
            return;
        }

        // Create task request body
        const payload = {
            id: 'test',
            scheduler_id: context.params.scheduleId,
            command: {
                type: 'running_state',
                value: 'start'
            }
        };
        const body = Buffer.from(JSON.stringify(payload)).toString('base64');

        // URL for cloud function task will call
        const url = 'https://us-central1-robots-277919.cloudfunctions.net/deviceCommand';

        // Create task request
        const task = {
            httpRequest: {
                httpMethod: 'POST',
                url,
                headers: {
                    'Content-Type': 'application/json',
                },
                body
            },
            scheduleTime: {
                seconds: snapshot.data()['time'].toDate() / 1000,
            },
            dispatchDeadline: {
                seconds: 60 // Retry for up to a minute. Check task queue for retry config settings.
            }
        };

        // Make Create Task request
        const request = { parent, task }
        const [response] = await cloudTasksClient.createTask(request);
        const name = response.name;
        console.log(`Created task ${name}`);
        
        return snapshot.ref.update({ 
            cloud_task_name: response.name
        }).then(() => {
            console.log('Firestore document updated with cloud_task_name');
            return true
        }).catch((err) => {
            console.error(err)
            return false
        });
    } 
};

exports.deleteHandler = async function(snapshot, context, serviceLocator) {

    if (snapshot.data()['cloud_task_name'] === undefined) {
        console.log('Cloud Tasks task not able to be deleted, "cloud_task_name" property not found.')
        return;
    }

    const task = {
        name: snapshot.data()['cloud_task_name']
    };
    
    return await cloudTasksClient.deleteTask(task);
};