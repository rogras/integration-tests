#!/bin/bash

# Set Which Environment are we in
# in case we are in CaaS, all tests starting with local-only will not be executed
if [[ $IS_CAAS = 0 ]]; then
        echo "Local environment, everything in yaml runs"

else
        echo "CaaS environment, oracle test are not going to run"
        sed -i "s/skip: _local-only.*/skip: true/g" /opt/landoop/tools/share/coyote/examples/kafka_tests.yml

fi


coyote -c /kafka_tests.yml -out /opt/landoop/tools/share/coyote/examples/coyote-test-$(date +%Y-%m-%d_%H:%M).html -json-out /opt/landoop/tools/share/coyote/examples/coyote-test-$(date +%Y-%m-%d_%H:%M).json
cd /opt/landoop/tools/share/coyote/examples/
cat $(ls *.json | tail -1)