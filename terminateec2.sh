#!/bin/bash

aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=mongodb,catalogue,user,cart,redis,mysql,rabbitmq,payment,shpping,forntend" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text