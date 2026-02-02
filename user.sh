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
dnf module disable nodejs -y &>>$LOGS_FILE
validation $? "nodejs module disabled"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
validation $? "nodejs module enabled"

dnf install nodejs -y &>>$LOGS_FILE
validation $? "nodejs installed"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    echo -e " $G User roboshop has been created $N"
else 
    echo -e  "$Y User already exists, skipping this step $N"
fi

mkdir -p /app
validation $? "creating an app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>>$LOGS_FILE
validation $? "Download catalogue code"

cd /app 
validation $? "Moving to app directory"

rm -rf /app/*
validation $? "removing the existing code"

unzip /tmp/user.zip &>>$LOGS_FILE
validation $? "unzipping the files"

cd /app
npm install &>>$LOGS_FILE
validation $? "installing dependencies" 

cp $SHELL_DIR/user.service /etc/systemd/system/user.service &>>$LOGS_FILE
validation $? "user service has been updated"

systemctl daemon-reload 
validation $? "system daemon reloaded"

systemctl enable user &>>$LOGS_FILE
validation $? "user service is enabled"

systemctl start user
validation $? "user service is started"