#! /bin/bash

yarn_site_xml=${HADOOP_HOME}/etc/hadoop/yarn-site.xml
mapred_site_xml=${HADOOP_HOME}/etc/hadoop/mapred-site.xml
capacity_site_xml=${HADOOP_HOME}/etc/hadoop/capacity-scheduler.xml

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/yarn-setttings.cfg

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
service_hosts=$(sed -r -n 's/(^service_hosts=)(.*)$/\2/p' $CONF_FILE)


modifyXMLconfig()
{
    inifile=$1
    section=$2
    configurationfile=$3
    if [ $# -ne 3 ] || [ ! -f ${inifile} ] ;then
        echo  "ini file not exist!"
        exit
    else
        keys=$(sed -E '/^#|^$/d' $inifile| awk '/\['$section'\]/{f=1;next} /\[*\]/{f=0} f'|awk '{print $1}')

        IFS=$'\n'

        while read -r i;
        do

            key=$i
            value=`sed -E '/^#|^$/d' $inifile | awk '/\['$section'\]/{a=1}a==1&&$1~/'$key'/{print $2;exit}' $inifile`

            local x=`grep -c ">$key<" $configurationfile`
            if [ $x -eq 0 ]; then
                CONTENT="\t<property>\n\t\t<name>$key</name>\n\t\t<value>$value</value>\n\t</property>"
                C=$(echo $CONTENT | sed 's/\//\\\//g')
                sed -i "/<\/configuration>/ s/.*/${C}\n&/" $configurationfile
            else
                sed -i "/>$key</{n;s#.*#\t<value>$value</value>#}" $configurationfile
            fi
        done <<< "$keys"
    fi
}


# ----------------------------------------------------------
#  config the file mapred-site.xml
# ----------------------------------------------------------
mapredsiteCount=$(grep -c ">mapreduce.framework.name<" $mapred_site_xml)
if  [ $mapredsiteCount -eq 0 ]; then
   modifyXMLconfig $CONF_FILE mapred_site $mapred_site_xml
   echo -e "\033[34m [step-3.1: config the file mapred-site.xml] File configuration successful! \033[0m"
else
   echo -e "\033[33m [step-3.1: config the file mapred-site.xml] The file configuration has been modified \033[0m"
fi


# ----------------------------------------------------------
# config the file yarn-site.xml
# ----------------------------------------------------------
yarn_service_hosts=$(grep -c ">$service_hosts<" $yarn_site_xml)
if  [ $yarn_service_hosts -eq 0 ]; then
   modifyXMLconfig $CONF_FILE yarn_site $yarn_site_xml
   echo -e "\033[34m [step-3.2: config the file yarn-site.xml] File configuration successful! \033[0m"
else
    echo -e "\033[33m [step-3.2: config the file yarn-site.xml] The file configuration has been modified \033[0m"
fi


# ----------------------------------------------------------
# config the capacity-scheduler.xml
# ----------------------------------------------------------
capacity_calculator=$(grep -c ">org.apache.hadoop.yarn.util.resource.DominantResourceCalculator<" $capacity_site_xml)
if  [ $capacity_calculator -eq 0 ]; then
   modifyXMLconfig $CONF_FILE capacity_scheduler $capacity_site_xml
   echo -e "\033[34m [step-3.3: config the file capacity-scheduler.xml] File configuration successful! \033[0m"
else
   echo -e "\033[33m [step-3.3: config the file capacity-scheduler.xml] The file configuration has been modified \033[0m"
fi
