#!/bin/bash

### UPDATE ROUTER

FLOW_ID=dd3d787a-7833-4581-9287-3ad2c5a1273a
NODE_ID=router
INSTANCE_ID=fcdd26a0-5d65-11e5-9fc2-63ce49df012b

KEY=$FLOW_ID/$INSTANCE_ID/$NODE_ID/config

ROUTER_CONFIG=$(redis-cli GET $KEY | jq 'setpath(["meshblu-output"]; getpath(["output"]))' | jq 'setpath(["meshblu-output", "type"]; "meshblu-output")')
redis-cli SET $KEY "$ROUTER_CONFIG"


### COPY OUTPUT NODE

redis-cli SET $FLOW_ID/$INSTANCE_ID/meshblu-output/config '{ "uuid": "dd3d787a-7833-4581-9287-3ad2c5a1273a", "token": "b24285d321c65758f4b43c34fd494467b4b8622e", "server": "meshblu.octoblu.com", "port": 443 }'
