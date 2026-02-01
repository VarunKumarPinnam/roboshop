USERID=$(id -u)
LOGS_DIRECTORY="/var/log/shell-script"
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
    echo -e "$R $2 failed $N" | tee -a $LOGS_FILE
    exit 1
  else
    echo -e "$G $2 completed $N" | tee -a $LOGS_FILE
 fi
}

echo -e "$Y starting...$N"
dnf install rabbitmq-server -y
validation $? "rabbitmrabbitMQ installation"

systemctl enable rabbitmq-server
validation $? "rabbitmrabbitMQ service enable"

systemctl start rabbitmq-server
validation $? "rabbitmrabbitMQ service start"

rabbitmqctl add_user roboshop roboshop123
validation $? "roboshop user creation"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
validation $? "persmissions update"

