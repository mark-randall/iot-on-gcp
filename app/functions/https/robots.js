'use strict';

const exec = require('child_process').exec;
const { v4: uuidv4 } = require('uuid');

exports.handler = function(request, response, admin) {

    switch (request.method.toLowerCase()) {
        case 'post':
            create(request,response, admin)
            break;
        case 'delete':
            destroy(request,response, admin)
            break;
        default:
            response.status(405).send({'success': false, 'result': request.method + ' not supported'});
            break;
    } 
};

// HTTP POST
function create(request, response, admin) {

    // Download GCP Deployment Manager template from GCS
    let bucket = admin.storage().bucket();
    bucket.file('robot_deployment_template.jinja').download({ destination: '/tmp/robot_deployment_template.jinja' })
    .then(() => {

        let startUpScriptURL = "gs://" + bucket.name + "/robot_startup_script.sh"

        // Deployment names must match '[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?'
        let id = uuidv4().replace(/-/g, '');
        let vmName = 'vm' + id

        // GCP Deployment Manager create cmd
        // Creates GCE instance
        // GCE runs startUpScriptURL
        // SEE: robot repo code or Bucket files for deployment details
        let cmd = 'gcloud deployment-manager deployments create ' + vmName + ' \
                --template /tmp/robot_deployment_template.jinja \
                --properties zone:us-central1-a,startup-script-url:' + startUpScriptURL

        // run cmd
        console.log('executing: ', cmd)
        exec(cmd, (err, stdout, stderr) => {
            if ((stderr === null || stderr.length === 0) && (err === null || err.length === 0)) {
                response.status(201).send({'success': true, 'result': {'id': id, 'output': stdout} });
            } else {
                execFailureResponse(response, err, stderr)
            }
        });
    })
    .catch((err) => {
        console.error('Unable to download file from bucket')
        response.status(400).send({'success': false, 'result': err});
    });
}

// HTTP DELETE
function destroy(request, response, admin) {

    let id = request.path.split('/').pop()
    let vmName = 'vm' + id

    // GCP Deployment Manager delete cmd
    // Success returns without stdout
    let cmd = 'gcloud deployment-manager deployments delete ' + vmName + ' --async -q'

    // run cmd 
    console.log('executing: ', cmd)
    exec(cmd, (err, stdout, stderr) => {
        if ((stderr === null || stderr.length === 0) && (err === null || err.length === 0)) {
            response.send({'success': true, 'result': stdout});
        } else {
            execFailureResponse(response, err, stderr)
        }
    });
}

// Send response for failed exec call
function execFailureResponse(response, err, stderr) {

    if (stderr !== null && stderr.length > 0) {
        response.status(400).send({'success': false, 'result': stderr});
    } else if (err !== null && err.length > 0) {
        response.status(400).send({'success': false, 'result': err});
    } else {
        response.status(500).send({'success': false, 'result': {}});
    }
}