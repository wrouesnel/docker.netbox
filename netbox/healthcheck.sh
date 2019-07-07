#!/bin/bash
# Docker Healthcheck - just check if the runit services are all running.

set -o pipefail

# Check the request works
curl -s -k https://127.0.0.1:561/metrics > /dev/null 2>&1
if [ $? != 0 ] ; then
    exit 1
fi

count=$(curl -s -k https://127.0.0.1:561/metrics | grep -P 'node_service_state{.*} 0' | wc -l)

if [ $count != 0 ]; then
    exit 1
fi

exit 0
