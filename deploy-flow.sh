#!/bin/bash

USER_UUID="ab8d9474-bd15-4a78-afca-891019f092e7"
USER_TOKEN="dd6aad70e40e6c3f58409283f8682736a8889aaa"
FLOW_UUID='a2d0ba1a-a0f3-4f2c-9062-14cd3e9c5ffe'

#URL="http://$USER_UUID:$USER_TOKEN@nanocyte-flow-deploy.octoblu.com/flows/$FLOW_UUID/instances"
URL="http://$USER_UUID:$USER_TOKEN@localhost:5051/flows/$FLOW_UUID/instances"
curl --silent -i -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
