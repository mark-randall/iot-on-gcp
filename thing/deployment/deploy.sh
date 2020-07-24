#! /bin/bash

BUCKETNAME="${DEVSHELL_PROJECT_ID}-testdevices"
STARTUP_SCRIPT_URL="gs://${BUCKETNAME}/robot_startup_script.sh"

create_infastructure()
{
    # Create bucket
    gsutil mb -c standard -l us-central1 gs://$BUCKETNAME

    # Upload startup script
    gsutil cp robot_startup_script.sh gs://$BUCKETNAME
}

# Deploy thing to Compute Engine
create_device_infastructure()
{
    DEPLOYMENT_NAME="dusty"

    # Use GCP Deployment Manager to create infastructure for project
    gcloud deployment-manager deployments create $DEPLOYMENT_NAME \
       --template robot_deployment_template.jinja \
       --properties zone:us-central1-a,startup-script-url:$STARTUP_SCRIPT_URL
}
