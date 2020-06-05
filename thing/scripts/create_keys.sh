#!/bin/bash

FILE=rsa_cert.pem
if [ -f "$FILE" ]; then
    echo "$FILE exists"
else 
    echo "Creating RSA cert"

    openssl req -x509 -newkey rsa:2048 -keyout rsa_private.pem -nodes -out rsa_cert.pem -subj "/CN=unused"
    openssl ecparam -genkey -name prime256v1 -noout -out ec_private.pem
    openssl ec -in ec_private.pem -pubout -out ec_public.pem
fi

exit 0

