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
    echo -e "$R $2 Failure $N" | tee -a $LOGS_FILE
    exit 1
  else
    echo -e "$G $2 Success $N" | tee -a $LOGS_FILE
 fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
validation $? "copying mongo repo"

dnf install mongodb-org -y | tee -a $LOGS_FILE
validation $? "mongo db server installation"

systemctl enable mongod &>>$LOGS_FILE
validation $? "enable mongo db"

systemctl start mongod &>> $LOGS_FILE
validation $? "start mongo db"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validation $? "allowing remote connections"

systemctl restart mongod &>> $LOGS_FILE
validation $? "restart mongodb"