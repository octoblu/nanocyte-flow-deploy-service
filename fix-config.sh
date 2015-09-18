#!/bin/bash

### UPDATE ROUTER

FLOW_ID=dd3d787a-7833-4581-9287-3ad2c5a1273a
INSTANCE_ID=0e505050-5e2a-11e5-a29d-99c2e61be901

# Update engine-output
KEY="$FLOW_ID/$INSTANCE_ID/engine-output/config"
redis-cli SET $KEY "$(redis-cli GET $KEY | jq 'del(.host)')"

# Update engine-debug
KEY="$FLOW_ID/$INSTANCE_ID/engine-debug/config"
DEBUG_CONFIG=$(redis-cli GET $KEY | sed -e 's/nodeUuid/nodeId/g')
redis-cli SET $KEY "$DEBUG_CONFIG"

# Update engine-pulse
KEY="$FLOW_ID/$INSTANCE_ID/engine-pulse/config"
PULSE_CONFIG=$(redis-cli GET $KEY | sed -e 's/nodeUuid/nodeId/g')
redis-cli SET $KEY "$PULSE_CONFIG"

# Update router
KEY="$FLOW_ID/$INSTANCE_ID/router/config"
DEBUG_LINKTO='["engine-debug","engine-pulse"]'
DEBUG_ID="106b1a01-5e2a-11e5-a29d-99c2e61be901"
ROUTER_CONFIG=$(redis-cli GET $KEY | jq "setpath([\"$DEBUG_ID\",\"linkedTo\"]; $DEBUG_LINKTO)")
redis-cli SET $KEY "$ROUTER_CONFIG"


