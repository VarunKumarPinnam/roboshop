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
dnf install python3 gcc python3-devel -y &>>$LOGS_FILE
validation $? "python installation"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    echo -e "$Y User roboshop has been created $N"
else 
    echo -e  "$Y User already exists, skipping this step $N"
fi


mkdir -p /app
validation $? "creating an app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>>$LOGS_FILE
validation $? "Download catalogue code"

cd /app 
validation $? "Moving to app directory"

rm -rf /app/*
validation $? "removing the existing code"

unzip /tmp/payment.zip &>>$LOGS_FILE
validation $? "unzipping the files"

cd /app
pip3 install -r requirements.txt &>>$LOGS_FILE
validation $? "installing dependencies" 

cp $SHELL_DIR/payment.service /etc/systemd/system/payment.service &>>$LOGS_FILE
validation $? "catalogue service has been updated"

systemctl daemon-reload 
validation $? "system daemon reloaded"

systemctl enable payment  &>>$LOGS_FILE
validation $? "payment  service enable"

systemctl start payment 
validation $? "payment  service start"
