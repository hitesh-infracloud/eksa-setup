#!/bin/bash

instance_ip=$1
file_path=$2
timeout=$3
start_time=$(date +%s)

while true; do
  if ssh -i ~/.aws/key-pairs/eksa-admin.pem -o StrictHostKeyChecking=no ubuntu@$instance_ip "test -e $file_path"; then
    echo "File exists: $file_path"
    break
  fi

  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))

  if [ "$elapsed_time" -gt "$timeout" ]; then
    echo "Timeout reached. File not created: $file_path"
    exit 1
  fi

  sleep 5
done

# Copy files using scp
scp -i ~/.aws/key-pairs/eksa-admin.pem -o StrictHostKeyChecking=no -r ../vm-scripts/ ubuntu@$instance_ip:/home/ubuntu/
echo "Files copied and connection successful"