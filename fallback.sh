#!/bin/bash
set -e

LOG_FILE="/var/log/fallback.log"

echo "==================================" | tee -a $LOG_FILE
echo "Fallback provisioning started" | tee -a $LOG_FILE
echo "Hostname : $(hostname)" | tee -a $LOG_FILE
echo "Date     : $(date)" | tee -a $LOG_FILE
echo "==================================" | tee -a $LOG_FILE

# Root check (important)
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Must be run as root" | tee -a $LOG_FILE
  exit 1
fi

echo "Updating OS packages..." | tee -a $LOG_FILE
yum -y update

echo "Installing common utilities..." | tee -a $LOG_FILE
yum install -y git curl wget net-tools unzip vim

echo "Creating standard directories..." | tee -a $LOG_FILE
mkdir -p /opt/roboshop /var/log/roboshop

echo "Creating app user if not exists..." | tee -a $LOG_FILE
id roboshop &>/dev/null || useradd roboshop

echo "Marking fallback execution..." | tee -a $LOG_FILE
echo "FALLBACK_EXECUTED=true" > /etc/roboshop-fallback

echo "Fallback provisioning completed successfully" | tee -a $LOG_FILE
