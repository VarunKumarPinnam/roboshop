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
    echo -e "$R $2 $N" | tee -a $LOGS_FILE
    exit 1
  else
    echo -e "$G $2 $N" | tee -a $LOGS_FILE
 fi
}

echo -e "$Y starting...$N"
dnf install mysql-server -y &>>$LOGS_FILE
validation $? "mysql installed"

systemctl enable mysqld &>>$LOGS_FILE
validation $? "mysql service enabled"

systemctl start mysqld  
validation $? "mysql service started"

mysql_secure_installation --set-root-pass RoboShop@1
validation $? "$Y root password has been updated.$N"