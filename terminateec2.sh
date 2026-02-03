aws ec2 describe-instances \
  --filters "Name=Name,Values=roboshop-user" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text