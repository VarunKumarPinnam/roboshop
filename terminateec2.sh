#!/bin/bash
set -e

#####################################
# CONFIG
#####################################
HOSTED_ZONE_NAME="advidevops.online."
SERVICE_NAMES="mongodb,catalogue,user,cart,redis,mysql,rabbitmq,payment,shipping,frontend"

#####################################
# STEP 1: GET HOSTED ZONE ID
#####################################
HZ_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name=='$HOSTED_ZONE_NAME'].Id" \
  --output text | cut -d'/' -f3)

if [ -z "$HZ_ID" ]; then
  echo "Hosted zone not found: $HOSTED_ZONE_NAME"
  exit 1
fi

echo "Hosted Zone ID: $HZ_ID"

#####################################
# STEP 2: DELETE DNS RECORDS (except NS & SOA)
#####################################
echo "Fetching DNS records to delete..."

aws route53 list-resource-record-sets \
  --hosted-zone-id "$HZ_ID" \
  --query "ResourceRecordSets[?Type=='A']" \
  --output json > records.json

COUNT=$(jq length records.json)

if [ "$COUNT" -eq 0 ]; then
  echo "No A records found to delete"
else
  echo "Deleting $COUNT A records..."

  jq '{Changes: map({Action:"DELETE", ResourceRecordSet:.})}' \
    records.json > delete-records.json

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$HZ_ID" \
    --change-batch file://delete-records.json
      echo "Deleted $COUNT A records"
fi

sleep 30

#####################################
# STEP 3: TERMINATE EC2 INSTANCES
#####################################
echo "Finding EC2 instances to terminate..."

INSTANCES=$(aws ec2 describe-instances \
  --filters \
    "Name=tag:Name,Values=$SERVICE_NAMES" \
    "Name=instance-state-name,Values=running,stopped" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

if [ -z "$INSTANCES" ]; then
  echo "No EC2 instances found"
  exit 0
fi

echo "Instances to be terminated:"
aws ec2 describe-instances \
  --instance-ids $INSTANCES \
  --query "Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key=='Name']|[0].Value}" \
  --output table

read -p "Type YES to terminate instances: " CONFIRM
[ "$CONFIRM" = "YES" ] || exit 1

aws ec2 terminate-instances --instance-ids $INSTANCES

echo "EC2 termination initiated"
