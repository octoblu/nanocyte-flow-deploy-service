#!/bin/bash
# meshbluAuth:
#   uuid: 'user-uuid'
#   token: 'user-token
USER_UUID="af354bd1-988f-4905-bba7-98b87f84eabe"
USER_TOKEN="b52d705520c9adf5e64afce81dc0d538095f2b09"
# FLOW_UUID='dd3d787a-7833-4581-9287-3ad2c5a1273a' # Bonzai
FLOW_UUID='c36f335a-d820-42bc-bedb-b08775931318' # Demultiplex Test

#URL="http://$USER_UUID:$USER_TOKEN@nanocyte-flow-deploy.octoblu.com/flows/$FLOW_UUID/instances"
URL="http://$USER_UUID:$USER_TOKEN@localhost:5051/flows/$FLOW_UUID/instances"
curl --silent -i -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
