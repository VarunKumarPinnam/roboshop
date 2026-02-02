#!/bin/bash

SG_ID="sg-02a915d53f8e3507f"
AMI_ID="ami-0532be01f26a3de55"
ZONE_ID="Z0148099BE47QLVOZU0Q"
DOMAIN_NAME="advidevops.online"
ROBOLOG_DIRECTORY="/var/log/roboshop"
ROBOLOG_FILE="$ROBOLOG_DIRECTORY/$0.log"

KEY_FILE="$HOME/.ssh/project-key.pem"
SSH_USER="ec2-user"
REPO_URL="https://github.com/VarunKumarPinnam/roboshop.git"
FALLBACK_SCRIPT="fallback.sh"

[ -f "$KEY_FILE" ] || { echo "ERROR: Key not found $KEY_FILE"; exit 1; }

> servers.txt   # capture server details

for instance in "$@"
do
  echo "=============================="
  echo "Creating instance: $instance"
  echo "=============================="

  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --key-name project-key \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

  echo "Instance ID: $INSTANCE_ID"

   #...WAIT until instance is running
  aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    #...Always fetch PUBLIC IP for SSH
  PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[*].Instances[*].[PublicIpAddress]' \
    --output text)

     # IP fetch to update DNS record
  if [ "$instance" == "frontend" ]; then 
    IP=$PUBLIC_IP
    RECORD_NAME="$DOMAIN_NAME"
  else
    IP=$(aws ec2 describe-instances \
      --instance-ids $INSTANCE_ID \
      --query 'Reservations[*].Instances[*].[PrivateIpAddress]' \
      --output text)
    RECORD_NAME="$instance.$DOMAIN_NAME"
  fi

  echo "DNS IP Address : $IP"

#...DNS record update
   aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Comment\": \"Update A record to $RECORD_NAME\",
      \"Changes\": [
        {
          \"Action\": \"UPSERT\",
          \"ResourceRecordSet\": {
            \"Name\": \"$RECORD_NAME\",
            \"Type\": \"A\",
            \"TTL\": 1,
            \"ResourceRecords\": [
              { \"Value\": \"$IP\" }
            ]
          }
        }
      ]
    }"

  echo "Record updated for $instance"

#...Capture server details
  echo "$instance,$INSTANCE_ID,$PUBLIC_IP" >> servers.txt

#...SSH + git clone + script execution
 echo "Provisioned $instance ($INSTANCE_ID) at $PUBLIC_IP"

echo "Waiting for SSH..."
  for i in {1..10}; do
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
        -i "$KEY_FILE" "$SSH_USER@$PUBLIC_IP" "echo SSH ready" && break
    sleep 10
  done


  ssh -o StrictHostKeyChecking=no -i "$KEY_FILE" "$SSH_USER@$PUBLIC_IP" <<EOF

    set -e

sudo mkdir -p $ROBOLOG_DIRECTORY
sudo chmod 777 $ROBOLOG_DIRECTORY

## Install git if not present
    if ! command -v git &>/dev/null; then
      sudo dnf install git -y &>>$ROBOLOG_FILE
    fi
    if [ ! -d "$(basename $REPO_URL .git)" ]; then
      git clone "$REPO_URL"
    fi

    cd "$(basename $REPO_URL .git)"

    SCRIPT_NAME="${instance}.sh"

    if [ -f "\$SCRIPT_NAME" ]; then
      echo "Running \$SCRIPT_NAME"
      chmod +x "\$SCRIPT_NAME"
      sudo "./\$SCRIPT_NAME"
    elif [ -f "$FALLBACK_SCRIPT" ]; then
      echo "WARNING: \$SCRIPT_NAME not found. Running fallback"
      chmod +x "$FALLBACK_SCRIPT"
      sudo "./$FALLBACK_SCRIPT"
    else
      echo "ERROR: No script found to execute"
      exit 1
    fi
EOF


  echo "Completed setup for $instance"
done

echo "================================="
echo "All instances created & configured"
echo "================================="