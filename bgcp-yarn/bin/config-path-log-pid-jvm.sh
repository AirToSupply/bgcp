#! /bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/yarn-setttings.cfg


modifyConf()
{
    inifile=$1
    section=$2
    configurationfile=$3
    if [ $# -ne 3 ] || [ ! -f ${inifile} ]
    then
        echo  "ini file not exist!"
        exit
    else
        keys=$(sed -E '/^#|^$/d' $inifile| awk -F ':' '/\['$section'\]/{f=1;next} /\[*\]/{f=0} f'|awk -F ':'  '{print $1}')

        IFS=$'\n'

        while read -r i;
        do
            key=$i
            value=`sed -E '/^#|^$/d' $inifile | awk -F ':' '/\['$section'\]/{a=1}a==1&&$1~/'$key'/{print $2;exit}' $inifile`

            conf=$(grep -Ev '^$|^#' $configurationfile)
            if [[ -n $key ]] && [[ `echo $conf | grep "$key"` != "" ]]; then
                k=`grep ^" *"$key $configurationfile | awk -F ':' '{print $1}'`
                sed -i "s#^$k.*#$k=${value}#g" $configurationfile
            elif [[ -n $key ]] && [[ `echo $conf | grep "$key"` = "" ]]; then
                echo $key=$value >> $configurationfile
            fi
        done <<< "$keys"
    fi
}


# --------------------------------------------------------------------------------------------------------------------------
# hadoop-env.sh
# --------------------------------------------------------------------------------------------------------------------------
# hadoop_env_file=$CONF_DIR/hadoop-env.sh
hadoop_env_file=${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
java_home_value=$(cat $hadoop_env_file | grep '^export JAVA_HOME=')
if [ -z "$java_home_value" ];then
  modifyConf $CONF_FILE hadoop_env $hadoop_env_file
  echo -e "\033[34m [step-7.1: hadoop change the configuration of log, pid, jvm] The hadoop-env.sh file configuration successful!  \033[0m"
else
  echo -e "\033[33m [step-7.1: hadoop change the configuration of log, pid, jvm] The hadoop-env.sh file has been configured! \033[0m"
fi


# --------------------------------------------------------------------------------------------------------------------------
# yarn-env.sh
# --------------------------------------------------------------------------------------------------------------------------
# yarn_env_file=$CONF_DIR/yarn-env.sh
yarn_env_file=${HADOOP_HOME}/etc/hadoop/yarn-env.sh

yarn_pid_dir_value=$(cat $yarn_env_file | grep '^export YARN_PID_DIR=')
if [ -z "$yarn_pid_dir_value" ];then
  modifyConf $CONF_FILE yarn_env $yarn_env_file

  echo -e "\033[34m [step-7.2: hadoop change the configuration of log, pid, jvm] The yarn-env.sh file configuration successful!  \033[0m"
else
  echo -e "\033[33m [step-7.2: hadoop change the configuration of log, pid, jvm] The yarn-env.sh file has been configured! \033[0m"
fi


# --------------------------------------------------------------------------------------------------------------------------
# mapred-env.sh
# --------------------------------------------------------------------------------------------------------------------------
# mapred_env_file=$CONF_DIR/mapred-env.sh
mapred_env_file=${HADOOP_HOME}/etc/hadoop/mapred-env.sh

hadoop_mapred_pid_dir_value=$(cat $mapred_env_file | grep '^export HADOOP_MAPRED_PID_DIR=')
if [ -z "$hadoop_mapred_pid_dir_value" ];then
  modifyConf $CONF_FILE mapred_env $mapred_env_file

  echo -e "\033[34m [step-7.3: hadoop change the configuration of log, pid, jvm] The mapred-env.sh file configuration successful!  \033[0m"
else
  echo -e "\033[33m [step-7.3: hadoop change the configuration of log, pid, jvm] The mapred-env.sh file has been configured! \033[0m"
fi
