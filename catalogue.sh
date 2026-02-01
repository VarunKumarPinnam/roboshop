USERID=$(id -u)
LOGS_DIRECTORY="/var/log/shell-mongodb"
LOGS_FILE="$LOGS_DIRECTORY/$0.log"
SHELL_DIR=$PWD
MONGODB_HOST="mongodb.advidevops.online"
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

dnf module disable nodejs -y &>>$LOGS_FILE
validation $? "nodejs module disabling is"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
validation $? "nodejs module enabling is"

dnf install nodejs -y &>>$LOGS_FILE
validation $? "nodejs installation is"

id roboshop 
if [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
    "User already exists, skipping this step"
fi

mkdir -p /app
validation $? "creating an app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
validation $? "Download catalogue code"

cd /app 
validation $? "Moving to app directory"

rm -rf /app/*
validation $? "removing the existing code"

unzip /tmp/catalogue.zip &>>$LOGS_FILE
validation $? "unzipping the files"

cd /app
npm install &>>$LOGS_FILE
validation $? "installing dependencies" 

cp $SHELL_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOGS_FILE
validation $? "catalogue service has been updated"

systemctl daemon-reload 
validation $? "system daemon reloaded"

systemctl enable catalogue 
validation $? "catalogue service enable is"

systemctl start catalogue
validation $? "catalogue service start is"

cp $SHELL_DIR/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y &>>$LOGS_FILE
validation $? "installing mongodb"

INDEX=$(mongosh --host $MONGODB_HOST  --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then 
   mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOGS_FILE
   validation $? "loading products"
else
    echo "data already loaded skipping this step"
fi 

systemctl restart catalogue
validation $? "system restart"



