#! /bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
LIB_DIR=`cd ${WORK_DIR};cd ../lib;pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/flink.cfg


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
deploy_user=$(sed -r -n 's/(^deploy_user=)(.*)$/\2/p' $CONF_FILE)
service_hosts=$(sed -r -n 's/(^service_hosts=)(.*)$/\2/p' $CONF_FILE)

# data directory
pid_dir=$(sed -r -n 's/(^pid_dir=)(.*)$/\2/p' $CONF_FILE)
log_dir=$(sed -r -n 's/(^log_dir=)(.*)$/\2/p' $CONF_FILE)

# decompress
flink_package_dir=$(sed -r -n 's/(^flink_package_dir=)(.*)$/\2/p' $CONF_FILE)
flink_deploy_dir=$(sed -r -n 's/(^flink_deploy_dir=)(.*)$/\2/p' $CONF_FILE)
flink_home_dir=$(sed -r -n 's/(^flink_home_dir=)(.*)$/\2/p' $CONF_FILE)


# ---------------------------------------------------------------------------
# step-1: Flink on Yarn installation environment detection
# ---------------------------------------------------------------------------
# Detect jdk, hadoop, zookeeper environment variables
echo -e "\033[34m [ step-1 : Detect jdk, hadoop environment variables ] \033[0m"
if [[ -z $JAVA_HOME || -z $HADOOP_HOME  ]];then
	echo -e "\033[31m JAVA_HOME or HADOOP_HOME  does not exist and does not meet the prerequisites for Yarn installation \033[0m"
	exit 0
fi


# ---------------------------------------------------------------------------
# step-2: Flink log data specified directory
# ---------------------------------------------------------------------------
if [ ! -d $pid_dir ];then
	sudo mkdir -p $pid_dir
	sudo chown -R $deploy_user:$deploy_user $pid_dir
fi

if [ ! -d $log_dir ];then
	sudo mkdir -p $log_dir
	sudo chown -R $deploy_user:$deploy_user $log_dir
fi
echo -e "\033[34m [step-2: Flink log data specified directory] has been created successfully! \033[0m"


# ---------------------------------------------------------------------------
# step-3: decompress
# ---------------------------------------------------------------------------
if [ ! -d $flink_home_dir ];then
    sudo tar -zxvf $flink_package_dir -C $flink_deploy_dir/
    sudo chown -R $deploy_user:$deploy_user $flink_home_dir
    echo -e "\033[34m [step-3: decompress] flink package has been decompressed successfully! \033[0m"
else
    echo -e "\033[31m [step-3: decompress] flink package has been already decompressed! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-4: Flink Environment Variables Injection
# ---------------------------------------------------------------------------
source ~/.bashrc
flink_home_value=$(cat ~/.bashrc | grep '^export FLINK_HOME=')
if [ -z "$flink_home_value" ];then
    echo -e "\n# Flink"                                              >> ~/.bashrc
    echo -e "export FLINK_HOME=$flink_home_dir"                      >> ~/.bashrc
    echo -e "export PATH=\$PATH:\$FLINK_HOME/bin"                    >> ~/.bashrc
    sleep 1s
    source ~/.bashrc
    echo -e "\033[34m [step-4: Flink Environment Variables Injection] has injected \$FLINK_HOME successfully! \033[0m"
else
    echo -e "\033[33m [step-4: Flink Environment Variables Injection] \$FLINK_HOME has been already existed! \033[0m"
fi
source ~/.bashrc


# ---------------------------------------------------------------------------
# step-5: Modify the masters and workers configuration files
# ---------------------------------------------------------------------------
masters_file=${FLINK_HOME}/conf/masters
masters_host_value=$(cat $masters_file | grep $service_hosts | wc -l)
if [[ $masters_host_value -ne 1 ]];then
	sudo rm -rf $masters_file
	sudo touch $masters_file
	sudo chown -R $deploy_user:$deploy_user $masters_file
	echo "$service_hosts:8281" >>$masters_file
	echo -e "\033[34m [step-5: Modify the masters configuration files] The masters file configuration successful!  \033[0m"
else
	echo -e "\033[33m [step-5: Modify the masters configuration files] The masters file has been configured!  \033[0m"
fi

workers_file=${FLINK_HOME}/conf/workers
workers_host_value=$(cat $workers_file | grep $service_hosts | wc -l)
if [[ $workers_host_value -ne 1 ]];then
	sudo rm -rf $workers_file
	sudo touch $workers_file
	sudo chown -R $deploy_user:$deploy_user $workers_file
	echo "$service_hosts" >>$workers_file
	echo -e "\033[34m [step-5: Modify the workers configuration files] The workers file configuration successful!  \033[0m"
else
	echo -e "\033[33m [step-5: Modify the workers configuration files] The workers file has been configured!  \033[0m"
fi


# ---------------------------------------------------------------------------
# step-6: Modify the flink-conf.yaml configuration file
# ---------------------------------------------------------------------------
flink_conf_file=${FLINK_HOME}/conf/flink-conf.yaml
flink_jobmanager_rpc_address=$(cat $flink_conf_file | grep "jobmanager.rpc.address" | awk -F ':' '{print $2}')
if [[ $flink_jobmanager_rpc_address != *"$service_hosts"* ]]; then
	sh ${WORK_DIR}/modify-conf.sh $CONF_FILE flink_conf $flink_conf_file
	echo -e "\033[34m [step-6: Modify the flink-conf.yaml configuration file ] The flink-conf.yaml file configuration successful! \033[0m"
else
	echo -e "\033[33m [step-6: Modify the flink-conf.yaml configuration file ] The flink-conf.yaml file has been configured! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-7: Modify the configuration of log, pid, and jvm
# ---------------------------------------------------------------------------
defalut_flink_log_dir_value=$(cat ${FLINK_HOME}/bin/config.sh | grep "DEFAULT_FLINK_LOG_DIR=")
if [[ $defalut_flink_log_dir_value = *"$log_dir"* ]];then
	echo -e "\033[33m [step-7: Modify the configuration of log, pid, and jvm] The config.sh file has been configured!  \033[0m"
else
	sed -i "s#DEFAULT_FLINK_LOG_DIR=\$FLINK_HOME_DIR_MANGLED/log#DEFAULT_FLINK_LOG_DIR=$log_dir#g" ${FLINK_HOME}/bin/config.sh
	sed -i 's#DEFAULT_ENV_PID_DIR="/tmp"#DEFAULT_ENV_PID_DIR="'$pid_log'"#g' ${FLINK_HOME}/bin/config.sh
	sed -i 's#DEFAULT_ENV_JAVA_OPTS=""#DEFAULT_ENV_JAVA_OPTS="-Xmx4096m"#g' ${FLINK_HOME}/bin/config.sh
	echo -e "\033[34m [step-7: Modify the workers configuration files] The config.sh file configuration successful!  \033[0m"
fi


# ---------------------------------------------------------------------------
# step-8: Supplementary jar package
# ---------------------------------------------------------------------------
flink_jars_value=$(ls ${FLINK_HOME}/lib | grep "commons-cli*" | wc -l)
if [[ $flink_jars_value -le 0 ]];then
	sudo cp $LIB_DIR/* ${FLINK_HOME}/lib/
	sudo chown -R $deploy_user:$deploy_user ${FLINK_HOME}/lib/
	echo -e "\033[34m [step-8: Supplementary jar package] Successfully added the jar package! \033[0m"
else
	echo -e "\033[33m [step-8: Supplementary jar package] jar package already exists! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-9: Supplement Hadoop dependency configuration
# --------------------------------------------------------------------------
flink_hadoop_classpath_value=$(cat ${FLINK_HOME}/bin/flink | grep "export HADOOP_CLASSPATH=")
if [[ -z $flink_hadoop_classpath_value ]];then
	sed -i '19 i export HADOOP_CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath)' ${FLINK_HOME}/bin/flink
	sed -i '23 i export HADOOP_CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath)' ${FLINK_HOME}/bin/sql-client.sh

	echo -e "\033[34m [step-9: Supplement Hadoop dependency configuration] file configuration successful! \033[0m"
else
	echo -e "\033[33m [step-9: Supplement Hadoop dependency configuration] has been configured!  \033[0m"
fi

echo -e "\033[34m [[  Flink on yarn integrated Juicefs configuration complete ]] file configuration successful!  \033[0m"
