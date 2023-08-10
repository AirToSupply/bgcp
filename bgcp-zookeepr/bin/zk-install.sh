#!/bin/bash
# 获取每个SECTION中所有的key和value并写入配置文件中
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
            if [ "$key" = "clientPort" ]; then
               value=${value:-2181}
            fi

            if [ "$key" = "dataDir" ]; then
               value=${value:-/data/zookeeper-3.6.3/snapshot}
            fi

            if [ "$key" = "dataLogDir" ]; then
               value=${value:-/data/zookeeper-3.6.3/transaction}
            fi

            if [ "$key" = "export JVMFLAGS" ]; then
               value=${value:-"-Xms2048m -Xmx2048m $JVMFLAGS"}
            fi

            if [ "$key" = "ZOO_LOG_DIR" ]; then
               value=${value:-"/data/zookeeper-3.6.3/log"}
            fi

            if [ "$key" = "ZOOPIDFILE" ]; then
               value=${value:-"/data/zookeeper-3.6.3/pid/zookeeper_server.pid"}
            fi

            if [ ! -f "$ZK_HOME/conf/java.env" ];then
               `touch $ZK_HOME/conf/java.env`
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


function install_zk ()
{
    packdir=$(sed -E '/^#.*|^ *$/d' conf/zk.cfg | grep -n '^pack_dir' |awk -F '=' '/pack_dir/ {print $2}')
    install_dir=$(sed -E '/^#.*|^ *$/d' conf/zk.cfg | grep -n '^install_dir'|awk -F '=' '/install_dir/ {print $2}')
    install_dir=${install_dir:-/opt}

    # 判断zookeeper目录是否存在
    if [ ! -d "$install_dir/apache-zookeeper-3.6.3-bin" ]; then
        echo `sudo tar -zxvf $packdir -C $install_dir`
        echo `sudo chown -R zhongtai:zhongtai $install_dir/apache-zookeeper-3.6.3-bin`
    fi

    # 判断zookeeper是否添加环境变量
    if [[ `cat ~/.bashrc | grep -n '^export ZK_HOME'` = "" ]]; then
        zk_home=$install_dir/apache-zookeeper-3.6.3-bin
    
        echo "# ZOOKEEPER" >> ~/.bashrc
        echo "export ZK_HOME=$zk_home" >> ~/.bashrc
        echo "export PATH=\$PATH:\$ZK_HOME/bin" >> ~/.bashrc
        `source ~/.bashrc`
    fi

    if [ ! -f "$ZK_HOME/conf/zoo.cfg" ]; then
        `cp $ZK_HOME/conf/zoo_sample.cfg $ZK_HOME/conf/zoo.cfg`
    fi


    listIniKeys conf/zk.cfg zoo.cfg $ZK_HOME/conf/zoo.cfg
    listIniKeys conf/zk.cfg JVM $ZK_HOME/conf/java.env
    listIniKeys conf/zk.cfg LOG $ZK_HOME/bin/zkEnv.sh
    listIniKeys conf/zk.cfg PID $ZK_HOME/bin/zkServer.sh

    zk_hosts=$(sed -E '/^#.*|^ *$/d' conf/zk.cfg | grep -n '^zk_hosts'|awk -F '=' '/zk_hosts/ {print $2}')
    # 这个是格式转换，将上面的变量转换成数组的格式
    zk_array=($(printf "%q\n" ${zk_hosts}))
    dataDir=$(grep ^" *"dataDir $ZK_HOME/conf/zoo.cfg | awk -F '=' '{print $2}')
    dataLogDir=$(grep ^" *"dataLogDir $ZK_HOME/conf/zoo.cfg |awk -F '=' '{print $2}')
    zooLogDir=$(grep ^" *"ZOO_LOG_DIR $ZK_HOME/bin/zkEnv.sh | awk -F '=' '{print $2}' | sed 's/\"//g')
    zooPidFile=$(grep ^" *"ZOOPIDFILE $ZK_HOME/bin/zkServer.sh | awk -F '=' '{print $2}' | sed 's/\"//g')

    # 定义一个变量conut，赋值为0，因为zookeeper是需要用到myid的
    count=0
    for (( i=0; i<${#zk_array[@]}; i++ ))
    do
        # 每次循环，count的值则会加1
        let count++
        if [[ `grep -Ev '\[|\]|^$|^#' $ZK_HOME/conf/zoo.cfg | grep "server.${count}"` != "" ]]; then
            `sed -i "s#^server.${count}.*#server.${count}=${zk_array[i]}:2888:3888#g" $ZK_HOME/conf/zoo.cfg`
        else  
            echo "server.${count}=${zk_array[i]}:2888:3888" >> $ZK_HOME/conf/zoo.cfg
        fi
    done

    # 开始安装zookeeper
    for (( i=0; i<${#zk_array[@]}; i++ ))
    do
        if ssh ${zk_array[i]} test -e $dataDir; then
            echo "$dataDir exists"
        else
            ssh ${zk_array[i]} "sudo mkdir -p $dataDir"
            ssh ${zk_array[i]} "sudo chown -R zhongtai:zhongtai $dataDir"
        fi

        if ssh ${zk_array[i]} test -e $dataLogDir; then
            echo "$dataLogDir exists"
        else
            ssh ${zk_array[i]} "sudo mkdir -p $dataLogDir"
            ssh ${zk_array[i]} "sudo chown -R zhongtai:zhongtai $dataLogDir"
        fi

        if ssh ${zk_array[i]} test -e $zooLogDir; then
            echo "$zooLogDir exists"
        else
            ssh ${zk_array[i]} "sudo mkdir -p $zooLogDir"
            ssh ${zk_array[i]} "sudo chown -R zhongtai:zhongtai $zooLogDir"
        fi

        zooPidPath=${zooPidFile%/*}
        if ssh ${zk_array[i]} test -e $zooPidPath; then
            echo "$zooPidPath exists"
        else
            ssh ${zk_array[i]} "sudo mkdir -p $zooPidPath"
            ssh ${zk_array[i]} "sudo chown -R zhongtai:zhongtai $zooPidPath"
        fi

        if ssh ${zk_array[i]} test -e $ZK_HOME; then
            echo "$ZK_HOME exists"
        else
            scp -r $ZK_HOME zhongtai@${zk_array[i]}:$install_dir
        fi

        if [[ `cat ~/.bashrc | ssh ${zk_array[i]} "grep -n '^export ZK_HOME'"` = "" ]]; then
            zk_home=$install_dir/apache-zookeeper-3.6.3-bin
            ssh ${zk_array[i]} 'echo "# ZOOKEEPER" >> ~/.bashrc'
            ssh ${zk_array[i]} 'echo "export ZK_HOME='$zk_home'" >> ~/.bashrc'
            ssh ${zk_array[i]} 'echo "export PATH=\$PATH:\$ZK_HOME/bin" >> ~/.bashrc'
            ssh ${zk_array[i]} 'source ~/.bashrc'
        fi

    done

    # 生成myid
    id_num=0
    for (( i=0; i<${#zk_array[@]}; i++ ))
    do
        let id_num++
        ssh ${zk_array[i]} "echo ${id_num} > $dataDir/myid"
    done
}

# 启动zookeeper
function start_zk ()
{
    zk_hosts=$(sed -E '/^#.*|^ *$/d' conf/zk.cfg | grep -n '^zk_hosts'|awk -F '=' '/zk_hosts/ {print $2}')
    # 这个是格式转换，将上面的变量转换成数组的格式
    zk_array=($(printf "%q\n" ${zk_hosts}))

    for (( i=0; i<${#zk_array[@]}; i++ ))
    do
        ssh ${zk_array[i]} "$ZK_HOME/bin/zkServer.sh restart"
    done
}

java -version
if [ $? = 0 ]; then
    install_zk
    start_zk
else
    echo "请先安装JDK8环境"
fi
