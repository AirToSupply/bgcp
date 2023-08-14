#! /bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
LIB_DIR=`cd ${WORK_DIR};cd ../lib;pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/redis.cfg


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
deploy_user=$(sed -r -n 's/(^deploy_user=)(.*)$/\2/p' $CONF_FILE)
service_hosts=$(sed -r -n 's/(^service_hosts=)(.*)$/\2/p' $CONF_FILE)

# data directory
log_dir=$(sed -r -n 's/(^log_dir=)(.*)$/\2/p' $CONF_FILE)
data_dir=$(sed -r -n 's/(^data_dir=)(.*)$/\2/p' $CONF_FILE)
run_dir=$(sed -r -n 's/(^run_dir=)(.*)$/\2/p' $CONF_FILE)

# decompress
package_dir=$(sed -r -n 's/(^package_dir=)(.*)$/\2/p' $CONF_FILE)
redis_package_dir=$(sed -r -n 's/(^redis_package_dir=)(.*)$/\2/p' $CONF_FILE)
redis_package_name=$(sed -r -n 's/(^redis_package_name=)(.*)$/\2/p' $CONF_FILE)
redis_home_dir=$(sed -r -n 's/(^redis_home_dir=)(.*)$/\2/p' $CONF_FILE)




# ---------------------------------------------------------------------------
# step-1: redis installation environment detection
# ---------------------------------------------------------------------------
# Detect jdk environment variables
echo -e "\033[34m [ step-1: Detect jdk environment variables] \033[0m"
if [[ -z $JAVA_HOME ]];then
	echo -e "\033[31m JAVA_HOME does not exist \033[0m"
	exit 0
fi

echo -e "\033[34m [ step-1: Detect gcc version] \033[0m"
gcc_version=$(rpm -qa gcc | awk '{print $1}')
if [[  -z $gcc_version ]];then
	echo -e "\033[33m gcc is not detected, start installing gcc and other redis compilation pre-dependencies \033[0m"
	rpm -Uvh $LIB_DIR/*.rpm --nodeps --force	
fi


# ---------------------------------------------------------------------------
# step-2: Redis log data specified directory
# ---------------------------------------------------------------------------
if [ ! -d $log_dir ];then
	sudo mkdir -p $log_dir
	sudo chown -R $deploy_user:$deploy_user $log_dir
fi

if [ ! -d $data_dir ];then
	sudo mkdir -p $data_dir
	sudo chown -R $deploy_user:$deploy_user $data_dir
fi


if [ ! -d $run_dir ];then
	sudo mkdir -p $run_dir
	sudo chown -R $deploy_user:$deploy_user $run_dir
fi
echo -e "\033[34m [step-2: Nacos log data specified directory] has been created successfully! \033[0m"


# ---------------------------------------------------------------------------
# step-3: decompressed and compiled 
# ---------------------------------------------------------------------------
if [ ! -d $redis_home_dir ];then
    # decompressed
    sudo tar -zxvf $redis_package_dir -C $package_dir
    sudo chown -R $deploy_user:$deploy_user $package_dir/$redis_package_name
    cd $package_dir/$redis_package_name

    # compiled
    sudo mkdir -p $redis_home_dir
    sudo chown -R $deploy_user:$deploy_user $redis_home_dir

    make && make install PREFIX=$redis_home_dir
    echo -e "\033[34m [step-3: decompressed and compiled ] redis package has been decompressed and compiled  successfully! \033[0m"
else
    echo -e "\033[31m [step-3: decompressed and compiled e] redis package has been already decompressed and compiled ! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-4: REDIS Environment Variables Injection
# ---------------------------------------------------------------------------
source ~/.bashrc
redis_home_value=$(cat ~/.bashrc | grep '^export REDIS_HOME=')
if [ -z "$redis_home_value" ];then
    echo -e "\n# REDIS"                                              >> ~/.bashrc
    echo -e "export REDIS_HOME=$redis_home_dir"                      >> ~/.bashrc
    echo -e "export PATH=\$PATH:\$REDIS_HOME/bin"                    >> ~/.bashrc
    sleep 1s
    source ~/.bashrc
    echo -e "\033[34m [step-4: REDIS Environment Variables Injection] has injected \$REDIS_HOME successfully! \033[0m"
else
    echo -e "\033[33m [step-4: REDIS Environment Variables Injection] \$REDIS_HOME has been already existed! \033[0m"
fi
source ~/.bashrc


# ---------------------------------------------------------------------------
# step-5: Redis configuration file
# ---------------------------------------------------------------------------
REDIS_CONF_FILE=${REDIS_HOME}/conf/redis.conf
if [ ! -f "$REDIS_CONF_FILE" ]; then
    # Create configuration directory
    sudo mkdir -p ${REDIS_HOME}/conf
    sudo chown -R $deploy_user:$deploy_user ${REDIS_HOME}/conf/
    # Create configuration file
    sudo mv $package_dir/$redis_package_name/redis.conf ${REDIS_HOME}/conf/
    sh ${WORK_DIR}/modify-conf.sh $CONF_FILE redis_conf $REDIS_CONF_FILE

    echo -e "\033[34m [step-5: Redis configuration file ] The redis.conf file configuration successful!  \033[0m"
else
    echo -e "\033[33m [step-5: Redis configuration file ] The redis.conf file has been configured! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-6: Start Redis
# ---------------------------------------------------------------------------
RedisCount=$(ps -aef | grep redis | grep -v grep | wc -l)
if [ $RedisCount -le 0 ];then
	${REDIS_HOME}/bin/redis-server ${REDIS_HOME}/conf/redis.conf
	echo -e "\033[34m [step-6: Start Redis] Redis started successfully!  \033[0m"
else
	echo -e "\033[33m [step-6: Start Redis] Redis process already exists! \033[0m"
fi
