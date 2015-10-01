#!/bin/bash

USER_UUID="4e565c47-e80f-44b3-b2da-9fe23bb60222"
USER_TOKEN="b7e34b86a047fbf5da83651fc1bfe56030903301"
FLOW_UUID='bf3fbc43-c90b-4e0d-a609-6f58caed29d9'

#URL="http://$USER_UUID:$USER_TOKEN@nanocyte-flow-deploy.octoblu.com/flows/$FLOW_UUID/instances"
URL="http://$USER_UUID:$USER_TOKEN@localhost:5051/flows/$FLOW_UUID/instances"
curl --silent -i -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
