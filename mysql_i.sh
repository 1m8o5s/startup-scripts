#!/bin/bash

sudo apt update
sudo apt install -y mysql-server
yes 123456 | sudo mysql_secure_installation
