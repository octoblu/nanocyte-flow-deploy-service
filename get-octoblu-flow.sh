#!/bin/bash


USER_UUID="af354bd1-988f-4905-bba7-98b87f84eabe"
USER_TOKEN="b52d705520c9adf5e64afce81dc0d538095f2b09"
FLOW_UUID='c36f335a-d820-42bc-bedb-b08775931318' # Demultiplex Test
curl "https://$USER_UUID:$USER_TOKEN@api.octoblu.com/api/flows/$FLOW_UUID"