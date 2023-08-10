#! /bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/nacos.cfg
APPLICATION_FILE=${NACOS_HOME}/conf/application.properties
NACOS_LOGBACK_FILE=${NACOS_HOME}/conf/nacos-logback.xml
NACOS_STARTUP_FILE=${NACOS_HOME}/bin/startup.sh
CLUSTER_FILE=${NACOS_HOME}/conf/cluster.conf


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
service_hosts=$(sed -r -n 's/(^service_hosts=)(.*)$/\2/p' $CONF_FILE)
data_dir=$(sed -r -n 's/(^data_dir=)(.*)$/\2/p' $CONF_FILE)
log_dir=$(sed -r -n 's/(^log_dir=)(.*)$/\2/p' $CONF_FILE)

# nacos cluster conf
nacos_cluster=$(sed -r -n 's/(^nacos_cluster=)(.*)$/\2/p' $CONF_FILE)

# nacos mysql metadata
spring_datasource=$(sed -r -n 's/(^spring_datasource=)(.*)$/\2/p' $CONF_FILE)



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
        keys=$(sed -E '/^#|^$/d' $inifile| awk '/\['$section'\]/{f=1;next} /\[*\]/{f=0} f'|awk  '{print $1}')

        IFS=$'\n'

        while read -r i;
        do
            key=$i
            value=`sed -E '/^#|^$/d' $inifile | awk '/\['$section'\]/{a=1}a==1&&$1~/'$key'/{print $2;exit}' $inifile`

            conf=$(grep -Ev '^$|^#' $configurationfile)
            if [[ -n $key ]] && [[ `echo $conf | grep "$key"` != "" ]]; then
                k=`grep ^" *"$key $configurationfile | awk '{print $1}'`
                sed -i "s#^$k.*#$k=${value}#g" $configurationfile
            elif [[ -n $key ]] && [[ `echo $conf | grep "$key"` = "" ]]; then
                echo $key=$value >> $configurationfile
            fi
        done <<< "$keys"
    fi
}


# ---------------------------------------------------------------------------
# cluster.conf
# ---------------------------------------------------------------------------
if [ ! -f "$CLUSTER_FILE" ]; then
	touch $CLUSTER_FILE
	echo "${nacos_cluster}" >>$CLUSTER_FILE
	echo -e "\033[34m [step-6: Nacos configuration file ] The cluster.conf file configuration successful!  \033[0m"
else
    echo -e "\033[33m [step-6: Nacos configuration file ] The cluster.conf file has been configured! \033[0m"
fi


# --------------------------------------------------------------------------------------------------------------------------
# application.properties
# --------------------------------------------------------------------------------------------------------------------------
spring_datasource_platform_value=$(cat $APPLICATION_FILE | grep '^spring.datasource.platform=')
if [ -z "$spring_datasource_platform_value" ];then
	# Modify metadata connection configuration
	modifyConf $CONF_FILE application_properties $APPLICATION_FILE

	echo -e "\033[34m [step-6: Nacos configuration file ] The application.properties file configuration successful!  \033[0m"
else
	echo -e "\033[33m [step-6: Nacos configuration file ] The application.properties file has been configured! \033[0m"
fi


# --------------------------------------------------------------------------------------------------------------------------
# nacos-logback.xml  Modify the log path related configuration in the file
# --------------------------------------------------------------------------------------------------------------------------
nacos_cmdb_log_value=$(cat $NACOS_LOGBACK_FILE | grep '${LOG_HOME}/cmdb-main.log')
if [ -z "$nacos_cmdb_log_value" ]; then
	sed -i 's#${nacos.home}/logs/cmdb-main.log#${LOG_HOME}/cmdb-main.log#g' $NACOS_LOGBACK_FILE
	sed -i "s#\${nacos.home}#$data_dir#g" $NACOS_LOGBACK_FILE

	echo -e "\033[34m [step-6: Nacos configuration file ] The nacos-logback.xml  file configuration successful!  \033[0m"
else
    echo -e "\033[33m [step-6: Nacos configuration file ] The nacos-logback.xml  file has been configured! \033[0m"
fi


# --------------------------------------------------------------------------------------------------------------------------
# startup.sh  Modify the log path related configuration in the file
# --------------------------------------------------------------------------------------------------------------------------
nacos_start_log_value=$(cat $NACOS_STARTUP_FILE | grep '^export NACOS_LOG=')
if [ -z "$nacos_start_log_value" ];then
	sed -i "/export CUSTOM_SEARCH_LOCATIONS=*/a export NACOS_LOG=$data_dir" $NACOS_STARTUP_FILE
	sed -i 's#${BASE_DIR}/logs#${NACOS_LOG}/logs#g' $NACOS_STARTUP_FILE
    echo -e "\033[34m [step-6: Nacos configuration file ] The startup.sh  file configuration successful!  \033[0m"
else
	echo -e "\033[33m [step-6: Nacos configuration file ] The startup.sh  file has been configured! \033[0m"
fi


