#!/bin/bash

USERID=$(id -u)
LOGS_DIRECTORY="/var/log/shell-script"
LOGS_FILE="$LOGS_DIRECTORY/$0.log"
SHELL_DIR=$PWD
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
    echo -e "$R $2..FAILED $N" | tee -a $LOGS_FILE
    exit 1
  else
    echo -e "$G $2..SUCCESS $N" | tee -a $LOGS_FILE
 fi
}

echo -e "$Y starting...$N"
dnf module disable nginx -y &>>$LOGS_FILE
validation $? "nginx module disabled"

dnf module enable nginx:1.24 -y &>>$LOGS_FILE
validation $? "nginx module enabled"

dnf install nginx -y &>>$LOGS_FILE
validation $? "nginx installated"

systemctl enable nginx &>>$LOGS_FILE
validation $? "$G enabled nginx service $N"

systemctl start nginx
validation $? "$G started nginx service $N"

rm -rf /usr/share/nginx/html/* 
validation $? "$Y removed default html content $N"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOGS_FILE
validation $? "$Y fronted code downloaded $N"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOGS_FILE
validation $? "$Y frontend code unzipped to html folder $N"

sed -i d /etc/nginx/nginx.conf 
validation $? "$Y removed default nginx config data $N"

cp $SHELL_DIR/nginx.service /etc/nginx/nginx.conf
validation $? "$Y updated new configuration to nginx.conf file $N"

systemctl restart nginx 
validation $? "$Y Nginx service restarted $N"