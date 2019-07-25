#!/bin/bash
sudo /etc/init.d/mysql stop
sudo /etc/init.d/redis-server stop
sudo invoke-rc.d rabbitmq-server stop
