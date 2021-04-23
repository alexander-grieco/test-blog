#!/bin/bash

set -e

exec > >(sudo tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo chmod +x /ops/scripts/start-client.sh
sudo bash -c "NOMAD_BINARY=${nomad_binary} CONSUL_BINARY=${consul_binary} /ops/scripts/start-client.sh \"${node_class}\" \"${retry_join}\" \"${encrypt_key_consul}\""
rm -rf /ops/
