#!/bin/bash

function install_seatunnel() {

    packdir=$(sed -E '/^#.*|^ *$/d' conf/seatunnel.cfg | grep -n '^pack_dir' |awk -F '=' '/pack_dir/ {print $2}')
    install_dir=$(sed -E '/^#.*|^ *$/d' conf/seatunnel.cfg | grep -n '^install_dir'|awk -F '=' '/install_dir/ {print $2}')
    install_dir=${install_dir:-/opt}
    seatunnel_hosts=$(sed -E '/^#.*|^ *$/d' conf/seatunnel.cfg | grep -n '^seatunnel_hosts'|awk -F '=' '/seatunnel_hosts/ {print $2}')
    # 这个是格式转换，将上面的变量转换成数组的格式
    seatunnel_array=($(printf "%q\n" ${seatunnel_hosts}))

    package=${packdir##*/}
    seatunnel_dir=${package%???????????}
    # 判断seatunnel目录是否存在
    if [ ! -d "$install_dir/$seatunnel_dir" ]; then
        echo `sudo tar -zxvf $packdir -C $install_dir`
    fi
    echo `sudo chown -R zhongtai:zhongtai $install_dir/$seatunnel_dir`

    seatunnel_home=$install_dir/$seatunnel_dir
    # 判断seatunnel是否添加环境变量
    if [[ `cat ~/.bashrc | ssh ${seatunnel_array[i]} "grep -n '^export SEATUNNEL_HOME'"` = "" ]]; then
        ssh ${seatunnel_array[i]} 'echo "# SEATUNNEL" >> ~/.bashrc'
        ssh ${seatunnel_array[i]} 'echo "export SEATUNNEL_HOME='$seatunnel_home'" >> ~/.bashrc'
        ssh ${seatunnel_array[i]} 'echo "export PATH=\$PATH:\$SEATUNNEL_HOME/bin" >> ~/.bashrc'
    else
        ssh ${seatunnel_array[i]} 'sed -i "s#^export SEATUNNEL_HOME.*#export SEATUNNEL_HOME='${seatunnel_home}'#g" ~/.bashrc'
    fi
    source ~/.bashrc

    # 配置flink环境变量
    if [[ `cat ~/.bashrc | grep -n '^export FLINK_HOME'` != "" ]]; then
        flink_home=$(sed -E '/^#.*|^ *$/d' ~/.bashrc | awk -F '=' '/export FLINK_HOME/ {print $2}')
        `sed -i "s#^FLINK_HOME.*#FLINK_HOME=\$\{FLINK_HOME:-$flink_home\}#g" $SEATUNNEL_HOME/config/seatunnel-env.sh`
    fi

    # 更新oracle jar包
    if [[ -f "$SEATUNNEL_HOME/lib/ojdbc8-12.2.0.1.jar" ]]; then
        `rm -rf $SEATUNNEL_HOME/lib/ojdbc8-12.2.0.1.jar`
        `cp lib/ojdbc8-21.5.0.0.jar $SEATUNNEL_HOME/lib`
    fi

    # 创建软连接
    `ln -s $SEATUNNEL_HOME/bin/start-seatunnel-flink-15-connector-v2.sh $SEATUNNEL_HOME/bin/start-seatunnel-flink.sh`

    if ssh ${seatunnel_array[i]} test -e $SEATUNNEL_HOME; then
        echo "$SEATUNNEL_HOME exists"
    else
        scp -r $SEATUNNEL_HOME zhongtai@${seatunnel_array[i]}:$install_dir
    fi
}

install_seatunnel
