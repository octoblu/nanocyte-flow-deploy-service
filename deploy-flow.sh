#!/bin/bash
# meshbluAuth:
#   uuid: 'user-uuid'
#   token: 'user-token
FLOW_UUID='dd3d787a-7833-4581-9287-3ad2c5a1273a'
FLOW_TOKEN='b24285d321c65758f4b43c34fd494467b4b8622e'

URL="http://$FLOW_UUID:$FLOW_TOKEN@localhost:5051/flows/$FLOW_UUID/instances"
curl -i -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
