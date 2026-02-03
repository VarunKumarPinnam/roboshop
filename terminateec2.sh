aws ec2 describe-instances \
  --filters "Name=tag.Name,Values=redis" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text