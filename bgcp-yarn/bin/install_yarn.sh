#! /bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/yarn-setttings.cfg

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
deploy_user=$(sed -r -n 's/(^deploy_user=)(.*)$/\2/p' $CONF_FILE)
service_hosts=$(sed -r -n 's/(^service_hosts=)(.*)$/\2/p' $CONF_FILE)
data_directory=$(sed -r -n 's/(^data_directory=)(.*)$/\2/p' $CONF_FILE)
pid_dir=$(sed -r -n 's/(^pid_dir=)(.*)$/\2/p' $CONF_FILE)
log_dir=$(sed -r -n 's/(^log_dir=)(.*)$/\2/p' $CONF_FILE)
yarn_timeline_dir=$(sed -r -n 's/(^yarn_timeline_dir=)(.*)$/\2/p' $CONF_FILE)

workers_ip_arrays=$(sed -r -n 's/(^workers_ip_arrays=)(.*)$/\2/p' $CONF_FILE)

# ---------------------------------------------------------------------------
# step-1: Process hadoop yarn installation predicate environment
# ---------------------------------------------------------------------------
# Detect jdk, hadoop, zookeeper environment variables
echo -e "\033[34m <<step-1.1: Detect jdk, hadoop, zookeeper environment variables>> \033[0m"
if [[ -z $JAVA_HOME || -z $HADOOP_HOME || -z $ZK_HOME ]];then
	echo -e "\033[31m JAVA_HOME or HADOOP_HOME or ZOOKEEPER_HOME does not exist and does not meet the prerequisites for Yarn installation \033[0m"
	exit 0
fi

# Check if the zookeeper process is started
echo -e "\033[34m <<step-1.2: Check if the zookeeper process is started>> \033[0m"
serverCount=$(ps -ef | grep "org.apache.zookeeper.server.quorum.QuorumPeerMain" | grep -v "grep" | wc -l)
if [ $serverCount -le 0 ];then
	echo -e "\033[31m  zookeeper Server [Inactive] \033[0m"
	exit 0
fi

# ----------------------------------------------------------
# step-2: Create  hadoop yarn log directory
# ----------------------------------------------------------

if [ ! -d $pid_dir ];then
   sudo mkdir -p $pid_dir
   sudo chown -R $deploy_user:$deploy_user $pid_dir
fi

if [ ! -d $log_dir ];then
   sudo mkdir -p $log_dir
   sudo chown -R $deploy_user:$deploy_user $log_dir
fi

if [ ! -d $yarn_timeline_dir ];then
   sudo mkdir -p $yarn_timeline_dir
   sudo chown -R $deploy_user:$deploy_user $yarn_timeline_dir
fi

echo -e "\033[33m [step-2: Create hadoop yarn log directory] has been created successfully! \033[0m"

# ----------------------------------------------------------
# step-3: config the file mapred-site.xml、yarn-site.xml、capacity-scheduler.xml
# ----------------------------------------------------------
sh $WORK_DIR/config-site-xml.sh

# ----------------------------------------------------------
# step-4: config the workers
# ----------------------------------------------------------
workers_fline=${HADOOP_HOME}/etc/hadoop/workers
rm -rf $workers_fline
touch $workers_fline
echo "${workers_ip_arrays}" >>$workers_fline
echo -e "\033[34m [step-6: config the workers] File configuration successful!  \033[0m"

# ----------------------------------------------------------
# step-5: hadoop change the configuration of log, pid, jvm
# ----------------------------------------------------------
sh $WORK_DIR/config-path-log-pid-jvm.sh
echo -e "\033[34m [step-7: hadoop change the configuration of log, pid, jvm] File configuration successful!  \033[0m"

# ---------------------------------------------------------------------------
# step-6: Start yarn-related processes
# ---------------------------------------------------------------------------
nodeManagerCount=$(jps |grep NodeManager | wc -l)
ResourceManagerCount=$(jps |grep ResourceManager | wc -l)
if [[ $nodeManagerCount -le 0 && $ResourceManagerCount -le 0 ]];then
	${HADOOP_HOME}/sbin/start-yarn.sh
	echo -e "\033[34m [step-8: Start yarn-related processes] yarn started successfully!  \033[0m"
else
    echo -e "\033[31m  NodeManager、 ResourceManager process already exists \033[0m"	
fi

JobHistoryServerCount=$(jps |grep JobHistoryServer | wc -l)
if [ $JobHistoryServerCount -le 0 ];then
	${HADOOP_HOME}/sbin/mr-jobhistory-daemon.sh start historyserver
	echo -e "\033[34m [step-8: Start yarn-related processes] yarn historyserver started successfully!  \033[0m"
else
	echo -e "\033[31m  JobHistoryServer process already exists \033[0m"
fi
