#!/bin/bash
# meshbluAuth:
#   uuid: 'user-uuid'
#   token: 'user-token
USER_UUID="4e565c47-e80f-44b3-b2da-9fe23bb60222"
USER_TOKEN="886d3621c1b92bae60f55d1847888b84afe1348c"
# FLOW_UUID='dd3d787a-7833-4581-9287-3ad2c5a1273a' # Bonzai
FLOW_UUID='6707e56b-7070-41d9-b706-7cf6fc7bbeb6' # Demultiplex Test

#URL="http://$USER_UUID:$USER_TOKEN@nanocyte-flow-deploy.octoblu.com/flows/$FLOW_UUID/instances"
URL="http://$USER_UUID:$USER_TOKEN@localhost:5051/flows/$FLOW_UUID/instances"
curl --silent -i -X DELETE -H 'Content-Type: application/json' -d "$DATA" "$URL"
