#!/bin/bash

listIniKeys()
{
    inifile="$1"
    section="$2"
    configurationfile="$3"
    if [ $# -ne 3 ] || [ ! -f ${inifile} ]
    then
        echo  "ini file not exist!"
        exit
    else
        keys=$(sed -E '/^#.*|^ *$/d' $inifile| awk -F '=' '/\['$section'\]/{f=1;next} /\[*\]/{f=0} f'|awk -F'=' '{print $1}')

        IFS=$'\n'

        while read -r i;
        do
            key=$i
            value=`sed -E '/^#.*|^ *$/d' $inifile | awk -F '=' '/\['$section'\]/{a=1}a==1&&$1~/'$key'/{print $2;exit}' $inifile`

            # 给指定参数设置默认值
            if [ "$key" = "installPath" ]; then
               value=${value:-${installPath:-"/opt/dolphinscheduler-3.1.5"}}
            fi

            if [ "$key" = "data.basedir.path" ]; then
               value=${value:-/data/dolphinscheduler-3.1.5/data}
            fi

            if [ "$key" = "hdfs.root.user" ]; then
               value=${value:-zhongtai}
            fi

            if [ "$key" = "DOLPHINSCHEDULER_PIDS_DIR" ]; then
               value=${value:-/data/dolphinscheduler-3.1.5/pid}
            fi

            if [ "$key" = "DOLPHINSCHEDULER_GARBAGE_COLLECTOR_DIR" ]; then
               value=${value:-/data/dolphinscheduler-3.1.5/gc}
            fi

            if [ "$key" = "DOLPHINSCHEDULER_LOGS_DIR" ]; then
               value=${value:-/data/dolphinscheduler-3.1.5/log}
            fi

            conf=$(grep -Ev '\[|\]|^$|^#' $configurationfile)
            if [[ -n $key ]] && [[ `echo $conf | grep "$key"` != "" ]]; then
                k=`grep ^" *"$key $configurationfile | awk -F '=' '{print $1}'`
                `sed -i "s#^$k.*#$k=${value}#g" $configurationfile`
            elif [[ -n $key ]] && [[ `echo $conf | grep "$key"` = "" ]]; then
                echo $key=$value >> $configurationfile
            fi
        done <<< "$keys"
    fi
}

init_application()
{
    inifile="$1"
    section="$2"
    configurationfile="$3"
    if [ $# -ne 3 ] || [ ! -f ${inifile} ]
    then
        echo  "ini file not exist!"
        exit
    else
        keys=$(sed -E '/^#.*|^ *$/d' $inifile| awk -F ': ' '/\['$section'\]/{f=1;next} /\[*\]/{f=0} f'|awk -F': ' '{print $1}')

        IFS=$'\n'
        while read -r i;
        do
            key=$i
            value=`sed -E '/^#.*|^ *$/d' $inifile | awk -F ': ' '/\['$section'\]/{a=1}a==1&&$1~/'$key'/{print $2;exit}' $inifile`
            value=$(echo "$value" | sed "s#\/#\\\/#g")

            flag=0
            cat $configurationfile | while read LINE
            do
                if [ $flag == 0 ]; then
                    if [ "$(echo $LINE | grep -E "^$section:")" != "" ]; then
                        flag=1
                        continue
                    fi
                fi
                if [ $flag == 1 ]; then
                    if [ "$(echo $LINE | grep "$key")" != "" ]; then
                        sed -i -e "/^$section:/,/$key:/{/^\([[:space:]]*$key: \).*/s//\1$value/}" $configurationfile
                    fi
                fi
            done
        done <<< "$keys"
    fi
}

init_nacos()
{   
    inifile="$1"
    section="$2"
    configurationfile="$3" 
    if [ $# -ne 3 ] || [ ! -f ${inifile} ]
    then
        echo  "ini file not exist!"
        exit
    else
        keys=$(sed -E '/^#.*|^ *$/d' $inifile| awk -F ': ' '/\['$section'\]/{f=1;next} /\[*\]/{f=0} f'|awk -F': ' '{print $1}')
        
        IFS=$'\n'
        while read -r i;
        do  
            key=$i
            value=`sed -E '/^#.*|^ *$/d' $inifile | awk -F ': ' '/\['$section'\]/{a=1}a==1&&$1~/'$key'/{print $2;exit}' $inifile`
            value=$(echo "$value" | sed "s#\/#\\\/#g")
            if [[ $value != "" ]]; then
                sed -i '/\# Override by profile/i\'$key': '$value'' $configurationfile
            else
                sed -i '/\# Override by profile/i\'$key'' $configurationfile
            fi
        done <<< "$keys"
    fi
}

function install_ds()
{
    packdir=$(sed -E '/^#.*|^ *$/d' conf/dolphinscheduler.cfg | grep -n '^pack_dir' |awk -F '=' '/pack_dir/ {print $2}')
    ds_path=${packdir%/*}
    ds_pack=${packdir##*/}
    ds_dir=${ds_pack%???????}

    installPath=$(sed -E '/^#.*|^ *$/d' conf/dolphinscheduler.cfg | grep -n '^installPath' |awk -F '=' '/installPath/ {print $2}')
    installPath=$(echo $installPath | awk -F "[\"\"]" '{print $2}')

    data_basedir_path=$(sed -E '/^#.*|^ *$/d' conf/dolphinscheduler.cfg | grep -n '^data.basedir.path' |awk -F '=' '/data.basedir.path/ {print $2}')

    resource_upload_path=$(sed -E '/^#.*|^ *$/d' conf/dolphinscheduler.cfg | grep -n '^resource.storage.upload.base.path' |awk -F '=' '/resource.storage.upload.base.path/ {print $2}')

    log_dir=$(sed -E '/^#.*|^ *$/d' conf/dolphinscheduler.cfg | grep -n '^DOLPHINSCHEDULER_LOGS_DIR' |awk -F '=' '/DOLPHINSCHEDULER_LOGS_DIR/ {print $2}')

    pid_dir=$(sed -E '/^#.*|^ *$/d' conf/dolphinscheduler.cfg | grep -n '^DOLPHINSCHEDULER_PIDS_DIR' |awk -F '=' '/DOLPHINSCHEDULER_PIDS_DIR/ {print $2}')

    gc_dir=$(sed -E '/^#.*|^ *$/d' conf/dolphinscheduler.cfg | grep -n '^DOLPHINSCHEDULER_GARBAGE_COLLECTOR_DIR' |awk -F '=' '/DOLPHINSCHEDULER_GARBAGE_COLLECTOR_DIR/ {print $2}')

    mysql_host=$(sed -E '/^#.*|^ *$/d' conf/dolphinscheduler.cfg | grep -n '^mysql_host' |awk -F '=' '/mysql_host/ {print $2}')

    mysql_username=$(sed -E '/^#.*|^ *$/d' conf/dolphinscheduler.cfg | grep -n '^mysql_username' |awk -F '=' '/mysql_username/ {print $2}')

    mysql_password=$(sed -E '/^#.*|^ *$/d' conf/dolphinscheduler.cfg | grep -n '^mysql_password' |awk -F '=' '/mysql_password/ {print $2}')

    JAVA_OPTS=$(sed -E '/^#.*|^ *$/d' conf/dolphinscheduler.cfg | grep -n '^JAVA_OPTS' |awk -F '=' '/JAVA_OPTS/ {print $2}')

    if [[ ! -d "$ds_path/$ds_dir" ]]; then
        echo `sudo tar -zxvf $packdir -C $ds_path`
        echo `sudo chown -R zhongtai:zhongtai $ds_path/$ds_dir`
    fi

    listIniKeys conf/dolphinscheduler.cfg install_env $ds_path/$ds_dir/bin/env/install_env.sh
    listIniKeys conf/dolphinscheduler.cfg dolphinscheduler_env $ds_path/$ds_dir/bin/env/dolphinscheduler_env.sh
    listIniKeys conf/dolphinscheduler.cfg common $ds_path/$ds_dir/alert-server/conf/common.properties
    listIniKeys conf/dolphinscheduler.cfg common $ds_path/$ds_dir/api-server/conf/common.properties
    listIniKeys conf/dolphinscheduler.cfg common $ds_path/$ds_dir/master-server/conf/common.properties
    listIniKeys conf/dolphinscheduler.cfg common $ds_path/$ds_dir/tools/conf/common.properties
    listIniKeys conf/dolphinscheduler.cfg common $ds_path/$ds_dir/worker-server/conf/common.properties
    listIniKeys conf/dolphinscheduler.cfg dolphinscheduler-daemon $ds_path/$ds_dir/bin/dolphinscheduler-daemon.sh
    init_application conf/dolphinscheduler.cfg spring $ds_path/$ds_dir/alert-server/conf/application.yaml
    init_application conf/dolphinscheduler.cfg spring $ds_path/$ds_dir/api-server/conf/application.yaml
    init_application conf/dolphinscheduler.cfg registry $ds_path/$ds_dir/api-server/conf/application.yaml
    init_nacos conf/dolphinscheduler.cfg spring.cloud $ds_path/$ds_dir/api-server/conf/application.yaml
    init_application conf/dolphinscheduler.cfg spring $ds_path/$ds_dir/master-server/conf/application.yaml
    init_application conf/dolphinscheduler.cfg registry $ds_path/$ds_dir/master-server/conf/application.yaml
    init_application conf/dolphinscheduler.cfg spring $ds_path/$ds_dir/worker-server/conf/application.yaml
    init_application conf/dolphinscheduler.cfg registry $ds_path/$ds_dir/worker-server/conf/application.yaml
    init_application conf/dolphinscheduler.cfg spring $ds_path/$ds_dir/tools/conf/application.yaml
    init_application conf/dolphinscheduler.cfg registry $ds_path/$ds_dir/tools/conf/application.yaml
    if [ $JAVA_OPTS != "" ]; then
        `sed -i "s/-Xms1g -Xmx1g/$JAVA_OPTS/g" $ds_path/$ds_dir/api-server/bin/start.sh`
    fi

    cp $HADOOP_HOME/etc/hadoop/core-site.xml $ds_path/$ds_dir/alert-server/conf
    cp $HADOOP_HOME/etc/hadoop/hdfs-site.xml $ds_path/$ds_dir/alert-server/conf
    cp $HADOOP_HOME/etc/hadoop/core-site.xml $ds_path/$ds_dir/api-server/conf
    cp $HADOOP_HOME/etc/hadoop/hdfs-site.xml $ds_path/$ds_dir/api-server/conf
    cp $HADOOP_HOME/etc/hadoop/core-site.xml $ds_path/$ds_dir/master-server/conf
    cp $HADOOP_HOME/etc/hadoop/hdfs-site.xml $ds_path/$ds_dir/master-server/conf
    cp $HADOOP_HOME/etc/hadoop/core-site.xml $ds_path/$ds_dir/worker-server/conf
    cp $HADOOP_HOME/etc/hadoop/hdfs-site.xml $ds_path/$ds_dir/worker-server/conf
    cp $HADOOP_HOME/etc/hadoop/core-site.xml $ds_path/$ds_dir/tools/conf
    cp $HADOOP_HOME/etc/hadoop/hdfs-site.xml $ds_path/$ds_dir/tools/conf

    cp $HADOOP_HOME/share/hadoop/mapreduce/lib/juicefs-hadoop-1.0.4.jar $ds_path/$ds_dir/alert-server/libs
    cp $HADOOP_HOME/share/hadoop/mapreduce/lib/juicefs-hadoop-1.0.4.jar $ds_path/$ds_dir/api-server/libs
    cp $HADOOP_HOME/share/hadoop/mapreduce/lib/juicefs-hadoop-1.0.4.jar $ds_path/$ds_dir/master-server/libs
    cp $HADOOP_HOME/share/hadoop/mapreduce/lib/juicefs-hadoop-1.0.4.jar $ds_path/$ds_dir/worker-server/libs

    if [[ -f "$ds_path/$ds_dir/api-server/libs/commons-cli-1.2.jar" ]]; then
        `rm -rf $ds_path/$ds_dir/api-server/libs/commons-cli-1.2.jar`
        `cp lib/commons-cli-1.4.jar $ds_path/$ds_dir/api-server/libs`
    fi
    if [[ -f "$ds_path/$ds_dir/master-server/libs/commons-cli-1.2.jar" ]]; then
        `rm -rf $ds_path/$ds_dir/master-server/libs/commons-cli-1.2.jar`
        `cp lib/commons-cli-1.4.jar $ds_path/$ds_dir/master-server/libs`
    fi
    if [[ -f "$ds_path/$ds_dir/worker-server/libs/commons-cli-1.2.jar" ]]; then
        `rm -rf $ds_path/$ds_dir/worker-server/libs/commons-cli-1.2.jar`
        `cp lib/commons-cli-1.4.jar $ds_path/$ds_dir/worker-server/libs`
    fi

    data_basedir_path=$(sed -E '/^#.*|^ *$/d' $ds_path/$ds_dir/api-server/conf/common.properties | grep -n '^data.basedir.path' |awk -F '=' '/data.basedir.path/ {print $2}')

    resource_upload_path=$(sed -E '/^#.*|^ *$/d' $ds_path/$ds_dir/api-server/conf/common.properties | grep -n '^resource.storage.upload.base.path' |awk -F '=' '/resource.storage.upload.base.path/ {print $2}')

    log_dir=$(sed -E '/^#.*|^ *$/d' $ds_path/$ds_dir/bin/dolphinscheduler-daemon.sh | grep -n '^DOLPHINSCHEDULER_LOGS_DIR' |awk -F '=' '/DOLPHINSCHEDULER_LOGS_DIR/ {print $2}')

    pid_dir=$(sed -E '/^#.*|^ *$/d' $ds_path/$ds_dir/bin/dolphinscheduler-daemon.sh | grep -n '^DOLPHINSCHEDULER_PIDS_DIR' |awk -F '=' '/DOLPHINSCHEDULER_PIDS_DIR/ {print $2}')

    gc_dir=$(sed -E '/^#.*|^ *$/d' $ds_path/$ds_dir/bin/dolphinscheduler-daemon.sh | grep -n '^DOLPHINSCHEDULER_GARBAGE_COLLECTOR_DIR' |awk -F '=' '/DOLPHINSCHEDULER_GARBAGE_COLLECTOR_DIR/ {print $2}')

    `hdfs dfs -test -e $resource_upload_path`
    if [ `echo $?` == 1 ]; then
        `hdfs dfs -mkdir $resource_upload_path`
    fi

    if [ ! -d "$log_dir" ]; then
        echo `sudo mkdir -p $log_dir`
        echo `sudo chown -R zhongtai:zhongtai $log_dir`
    fi
    if [ ! -d "$pid_dir" ]; then
        echo `sudo mkdir -p $pid_dir`
        echo `sudo chown -R zhongtai:zhongtai $pid_dir`
    fi
    if [ ! -d "$gc_dir" ]; then
        echo `sudo mkdir -p $gc_dir`
        echo `sudo chown -R zhongtai:zhongtai $gc_dir`
    fi
    if [ ! -d "$data_basedir_path" ]; then
        echo `sudo mkdir -p $data_basedir_path`
        echo `sudo chown -R zhongtai:zhongtai $data_basedir_path`
    fi

    ds_username=$(sed -E '/^#.*|^ *$/d' $ds_path/$ds_dir/bin/env/dolphinscheduler_env.sh | grep -n '^export SPRING_DATASOURCE_USERNAME' |awk -F '=' '/export SPRING_DATASOURCE_USERNAME/ {print $2}')
    ds_password=$(sed -E '/^#.*|^ *$/d' $ds_path/$ds_dir/bin/env/dolphinscheduler_env.sh | grep -n '^export SPRING_DATASOURCE_PASSWORD' |awk -F '=' '/export SPRING_DATASOURCE_PASSWORD/ {print $2}')
    ds_database=$(sed -E '/^#.*|^ *$/d' $ds_path/$ds_dir/bin/env/dolphinscheduler_env.sh | grep -n '^export SPRING_DATASOURCE_URL' |awk -F '=' '/export SPRING_DATASOURCE_URL/ {print $2}')
    ds_database=${ds_database##*/}

    ifuser=$(mysql -h$mysql_host -u$mysql_username -p$mysql_password -e "select user from mysql.user where user='$ds_username' limit 1")
    if [[ `echo $ifuser | grep $ds_username` == "" ]]; then
        `mysql -h$mysql_host -u$mysql_username -p$mysql_password -e "CREATE USER '$ds_username'@'%' IDENTIFIED BY '$ds_password';"`
    fi
    ifdatabase=$(mysql -h$mysql_host -u$mysql_username -p$mysql_password -e "SHOW DATABASES LIKE '$ds_database';")
    if [[ `echo $ifdatabase | grep $ds_database` == "" ]]; then
        `mysql -h$mysql_host -u$mysql_username -p$mysql_password -e "CREATE DATABASE $ds_database DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"`
        `mysql -h$mysql_host -u$mysql_username -p$mysql_password -e "GRANT ALL PRIVILEGES ON $ds_database.* TO '$ds_username'@'%';"`
        `mysql -h$mysql_host -u$mysql_username -p$mysql_password -e "FLUSH PRIVILEGES;"`
        `mysql -h$mysql_host -u$ds_username -p$ds_password -D$ds_database < sql/dolphinscheduler.sql`
    fi

    echo `$ds_path/$ds_dir/bin/install.sh`
    
}

if [[ `ps -ef | grep mysql | wc -l` == 1 && `ps -ef | grep zookeeper | wc -l` == 1 ]]; then
    echo "请先安装zookeeper和mysql"
else
    install_ds
fi
