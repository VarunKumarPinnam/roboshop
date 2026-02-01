#!/bin/bash

USERID=$(id -u)
LOGS_DIRECTORY="/var/log/shell-mongodb"
LOGS_FILE="$LOGS_DIRECTORY/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

#--ROOT User Check--
if [ "$USERID" -ne 0 ]; then 
    echo -e "$R You must run this script with root access $N" 
    exit 1
fi

#--Log Setup---
mkdir -p $LOGS_DIRECTORY


validation()
{
  if [ $1 -ne 0 ]; then 
    echo -e "$R $2 $N" | tee -a $LOGS_FILE
    exit 1
  else
    echo -e "$G $2 $N" | tee -a $LOGS_FILE
 fi
}


dnf module disable redis -y &>>$LOGS_FILE
validation $? "redis module disabled"

dnf module enable redis:7 -y &>>$LOGS_FILE
validation $? "redis module enabled"

dnf install redis -y  &>>$LOGS_FILE
validation $? "redis installated"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf
validation $? "$Y updated binding ip to 0.0.0.0 $N"

sed -i 's/protected-mode yes/protected-mode no/g' /etc/redis/redis.conf
validation $? "$Y updated protected mode to no $N"

systemctl enable redis &>>$LOGS_FILE
validation $? "$G enabled redis service $N"

systemctl start redis
validation $? "$G started redis service $N"

