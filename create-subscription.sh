#!/bin/bash


USER_UUID="af354bd1-988f-4905-bba7-98b87f84eabe"
USER_TOKEN="b52d705520c9adf5e64afce81dc0d538095f2b09"
FLOW_UUID='c36f335a-d820-42bc-bedb-b08775931318' # Demultiplex Test
EMITTER_UUID='af354bd1-988f-4905-bba7-98b87f84eabe'

curl -i -X POST "https://$USER_UUID:$USER_TOKEN@meshblu.octoblu.com/v2/devices/$FLOW_UUID/subscriptions/$EMITTER_UUID/broadcast"
  
