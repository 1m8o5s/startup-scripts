#!/bin/bash
if [ -f .env ]
then
  export $(cat .env | xargs)
else
  export USE_SETUP_VALIDATE_PASSWORD_SCRIPT=n
  export MYSQL_PASSWORD=123456
  export CONTINUE_WITH_PASSWORD_PROVIDED=y
  export REMOVE_ANONYMOUS_USERS=y
  export DISALLOW_ROOT_LOGIN_REMOTELY=n
  export REMOVE_TEST_DB_AND_ACCESS_TO_IT=y
  export RELOAD_PRIVILEGE_TABLES_NOW=y
fi
if [[ -z $1 ]]
then
	echo "we will install nothing"
else
	for i in $*
	do
		if [[ $i = "docker" ]]
		then
			curl -fsSL https://get.docker.com -o get-docker.sh
			sudo sh get-docker.sh
			rm get-docker.sh
			sudo usermod -aG docker $USER
		elif [[ $i = "compose" ]]
		then
			sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
			sudo chmod +x /usr/local/bin/docker-compose
		elif [[ $i = "mysql" ]]
		then
			sudo apt update
			sudo apt install -y mysql-server

			sudo apt-get install -y expect

			SECURE_MYSQL=$(sudo expect -c "
			set timeout 10
			spawn mysql_secure_installation
			expect \"Press y|Y for Yes, any other key for No:\"
			send \"$USE_SETUP_VALIDATE_PASSWORD_SCRIPT\r\"
			expect \"New password:\"
			send \"$MYSQL_PASSWORD\r\"
			expect \"Re-enter new password:\"
			send \"$MYSQL_PASSWORD\r\"
			expect \"Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :\"
			send \"$CONTINUE_WITH_PASSWORD_PROVIDED\r\"
			expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) :\"
			send \"$REMOVE_ANONYMOUS_USERS\r\"
			expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No) :\"
			send \"$DISALLOW_ROOT_LOGIN_REMOTELY\r\"
			expect \"Remove test database and access to it?\"
			send \"$REMOVE_TEST_DB_AND_ACCESS_TO_IT\r\"
			expect \"Reload privilege tables now?\"
			send \"$RELOAD_PRIVILEGE_TABLES_NOW\r\"
			expect eof
			")
			echo "$SECURE_MYSQL"
			sudo apt-get remove -y expect
			sudo systemctl enable mysql
		elif [[ $i = "mongodb" ]]
		then
			wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add - || \
			sudo apt-get install gnupg && \
			wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
			echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
			sudo apt-get update
			sudo apt-get install -y mongodb-org
			echo "mongodb-org hold" | sudo dpkg --set-selections
			echo "mongodb-org-server hold" | sudo dpkg --set-selections
			echo "mongodb-org-shell hold" | sudo dpkg --set-selections
			echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
			sudo systemctl enable mongod
		fi
	done
fi
