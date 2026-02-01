USERID=$(id -u)
LOGS_DIRECTORY="/var/log/shell-script"
LOGS_FILE="$LOGS_DIRECTORY/$0.log"
MYSQL="mysql.advidevops.online"
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

echo -e "$Y starting...$N"

dnf install maven -y &>>$LOGS_FILE
validation $? "maven installed"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    echo -e "User roboshop has been created"
else 
    echo -e  "$Y User already exists, skipping this step $N"
fi

mkdir -p /app
validation $? "creating an app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOGS_FILE
validation $? "Download shipping code"

cd /app 
validation $? "Moving to app directory"

rm -rf /app/*
validation $? "removing the existing code"

unzip /tmp/shipping.zip &>>$LOGS_FILE
validation $? "unzipping the files"

cd /app
mvn clean package &>>$LOGS_FILE
validation $? "installing dependencies" 

mv target/shipping-1.0.jar shipping.jar 

cp $SHELL_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOGS_FILE
validation $? "shipping service has been updated"

systemctl daemon-reload 
validation $? "system daemon reloaded"

systemctl enable shipping &>>$LOGS_FILE
validation $? "shipping service enable is"

systemctl start shipping
validation $? "shipping service start is"

#......Installing mysql client......#

dnf install mysql -y &>>$LOGS_FILE
validation $? "mysql client is installed"

mysql -h $mysql -uroot -pRoboShop@1 < /app/db/schema.sql
validation $? "loaded schema to db"

mysql -h $mysql -uroot -pRoboShop@1 < /app/db/app-user.sql
validation $? "created new user in mysql database"

mysql -h $mysql -uroot -pRoboShop@1 < /app/db/master-data.sql
validation $? "master data loaded to db"

systemctl restart shipping
validation $? "shiping service restarted"

