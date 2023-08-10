#! /bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/nacos.cfg


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
deploy_user=$(sed -r -n 's/(^deploy_user=)(.*)$/\2/p' $CONF_FILE)
service_hosts=$(sed -r -n 's/(^service_hosts=)(.*)$/\2/p' $CONF_FILE)

log_dir=$(sed -r -n 's/(^log_dir=)(.*)$/\2/p' $CONF_FILE)

# decompress
nacos_package_dir=$(sed -r -n 's/(^nacos_package_dir=)(.*)$/\2/p' $CONF_FILE)
nacos_package_name=$(sed -r -n 's/(^nacos_package_name=)(.*)$/\2/p' $CONF_FILE)
nacos_deploy_dir=$(sed -r -n 's/(^nacos_deploy_dir=)(.*)$/\2/p' $CONF_FILE)
nacos_deploy_name=$(sed -r -n 's/(^nacos_deploy_name=)(.*)$/\2/p' $CONF_FILE)
nacos_home_dir=$(sed -r -n 's/(^nacos_home_dir=)(.*)$/\2/p' $CONF_FILE)

# nacos mysql metadata
username=$(sed -r -n 's/(^username=)(.*)$/\2/p' $CONF_FILE)
password=$(sed -r -n 's/(^password=)(.*)$/\2/p' $CONF_FILE)
host=$(sed -r -n 's/(^host=)(.*)$/\2/p' $CONF_FILE)
port=$(sed -r -n 's/(^port=)(.*)$/\2/p' $CONF_FILE)
nacos_database_name=$(sed -r -n 's/(^nacos_database_name=)(.*)$/\2/p' $CONF_FILE)


# ---------------------------------------------------------------------------
# step-1: nacos installation environment detection
# ---------------------------------------------------------------------------
# Detect jdk environment variables
echo -e "\033[34m [ step-1: Detect jdk environment variables] \033[0m"
if [[ -z $JAVA_HOME ]];then
	echo -e "\033[31m JAVA_HOME does not exist \033[0m"
	exit 0
fi


# ---------------------------------------------------------------------------
# step-2: Nacos log data specified directory
# ---------------------------------------------------------------------------
if [ ! -d $log_dir ];then
	sudo mkdir -p $log_dir
	sudo chown -R $deploy_user:$deploy_user $log_dir
fi
echo -e "\033[34m [step-2: Nacos log data specified directory] has been created successfully! \033[0m"


# ---------------------------------------------------------------------------
# step-3: decompress
# ---------------------------------------------------------------------------
if [ ! -d $nacos_home_dir ];then
    sudo tar -zxvf $nacos_package_dir -C $nacos_deploy_dir
    sudo mv $nacos_deploy_dir/$nacos_package_name  $nacos_deploy_dir/$nacos_deploy_name
    sudo chown -R $deploy_user:$deploy_user $nacos_home_dir
    echo -e "\033[34m [step-3: decompress] nacos package has been decompressed successfully! \033[0m"
else
    echo -e "\033[31m [step-3: decompress] nacos package has been already decompressed! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-4: NACOS Environment Variables Injection
# ---------------------------------------------------------------------------
source ~/.bashrc
nacos_home_value=$(cat ~/.bashrc | grep '^export NACOS_HOME=')
if [ -z "$nacos_home_value" ];then
    echo -e "\n# NACOS"                                              >> ~/.bashrc
    echo -e "export NACOS_HOME=$nacos_home_dir"                      >> ~/.bashrc
    echo -e "export PATH=\$PATH:\$NACOS_HOME/bin"                    >> ~/.bashrc
    sleep 1s
    echo -e "\033[34m [step-4: NACOS Environment Variables Injection] has injected \$NACOS_HOME successfully! \033[0m"
else
    echo -e "\033[31m [step-4: NACOS Environment Variables Injection] \$NACOS_HOME has been already existed! \033[0m"
fi
source ~/.bashrc


# ---------------------------------------------------------------------------
# step-5: nacos metadata     
# ---------------------------------------------------------------------------
result=$( mysql -u ${username} -h $host -P $port -p$password -e "SHOW DATABASES LIKE '$nacos_database_name';")
if [[ $result = *"$nacos_database_name"* ]]; then
	echo -e "\033[31m [step-5: nacos metadata] nacos metadata already exists! \033[0m"
else
    mysql -u ${username} -h $host -P $port -p$password -e "CREATE DATABASE IF NOT EXISTS $nacos_database_name;use $nacos_database_name;source ${NACOS_HOME}/conf/nacos-mysql.sql;"
	echo -e "\033[34m [step-5: nacos metadata] has been created successfully! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-6: Nacos configuration file
# ---------------------------------------------------------------------------
sh $CONF_DIR/config-application.sh


# ---------------------------------------------------------------------------
# step-7: Start Nacos
# ---------------------------------------------------------------------------
NacosServerCount=$(ps -ef | grep "nacos.nacos" | grep -v grep | wc -l)
if [ $NacosServerCount -le 0 ];then
	${NACOS_HOME}/bin/startup.sh -m standalone
	echo -e "\033[34m [step-7: Start Nacos] Nacos started successfully! \033[0m"
else
	echo -e "\033[33m [step-7: Start Nacos] Nacos process already exists! \033[0m"
fi
