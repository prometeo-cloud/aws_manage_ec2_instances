#!/usr/bin/env bash
## Update base image with latest patches
sudo yum update * -y | tee /var/log/yum-update.log

## Install Advanced CloudWatch Monitoring Scripts
sudo yum install perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https -y
sudo yum install perl-Digest-SHA.x86_64 -y
sudo yum install unzip -y
sudo mkdir /CloudWatch
cd /CloudWatch
sudo curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip -O
sudo unzip CloudWatchMonitoringScripts-1.2.1.zip
sudo rm -rf CloudWatchMonitoringScripts-1.2.1.zip
cd aws-scripts-mon
sudo touch CloudWatchtest.log
sudo chmod 0666 CloudWatchtest.log
sudo ./mon-put-instance-data.pl --mem-util --verify --verbose > CloudWatchtest.log
sudo ./mon-put-instance-data.pl --mem-util --mem-used --mem-avail | tee cloudwatch-monitoring.log
