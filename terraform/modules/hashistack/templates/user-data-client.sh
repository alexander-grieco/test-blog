#!/bin/bash

set -e

exec > >(sudo tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo chmod +x /ops/scripts/client.sh
sudo bash -c "NOMAD_BINARY=${nomad_binary} /ops/scripts/start-client.sh \"${node_class}\" \"${retry_join}\""
rm -rf /ops/