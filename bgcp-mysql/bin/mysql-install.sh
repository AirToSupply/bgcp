#!/bin/bash

# 获取每个SECTION中所有的key和value并写入配置文件中
function listIniKeys ()
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
            value=`sed -E '/^#.*|^ *$/d' $inifile | awk -F '=' '/\['$section'\]/{a=1}a==1&&$1=="'$key'"{print $2;exit}' $inifile`
#            value=`sed -E '/^#.*|^ *$/d' $inifile | awk -F '=' '/\['$section'\]/{a=1}a==1&&$1~/'$key'/{print $2;exit}' $inifile`
            # 给指定参数设置默认值
            if [ "$key" = "port" ]; then
               value=${value:-3306}
            fi

            if [ "$key" = "datadir" ]; then
               value=${value:-/data/mysql-8.0.22/data}
            fi

            if [ "$key" = "socket" ]; then
               value=${value:-$install_dir/mysql-8.0.22/mysql.sock}
            fi

            if [ "$key" = "basedir" ]; then
               value=${value:-$install_dir/mysql-8.0.22}
            fi

            if [ "$key" = "log-error" ]; then
               value=${value:-/data/mysql-8.0.22/log/mariadb.log}
            fi

            if [ "$key" = "pid-file" ]; then
               value=${value:-/data/mysql-8.0.22/pid/mariadb.pid}
            fi

            if [ "$key" = "default-character-set" ]; then
               value=${value:-utf8}
            fi

            if [ "$key" = "max_connections" ]; then
               value=${value:-2048}
            fi

            # 判断section是否存在
            if [[ `grep -Ev '^$|^#' $configurationfile | grep "^\[$section\]"` = "" ]]; then
                `sudo sed -i '1i['$section']' $configurationfile`
            fi

            my_keys=$(sed -E '/^#.*|^ *$/d' $configurationfile | awk -F '=' '/\['$section'\]/{f=1;next} /\[*\]/{f=0} f'|awk -F'=' '{print $1}')

            if grep -q "$key" <<< "$my_keys"; then
                `sudo sed -i "s|^[#]*[ ]*${key}\([ ]*\)=.*|${key}=${value}|" $configurationfile`
            else
                `sudo sed -i '/^\['$section'\]/ a\'$key=$value'' $configurationfile`
            fi
        done <<< "$keys"
    fi
}

function install_mysql ()
{
    packdir=$(sed -E '/^#.*|^ *$/d' conf/mysql.cfg | grep -n '^pack_dir' |awk -F '=' '/pack_dir/ {print $2}')
    install_dir=$(sed -E '/^#.*|^ *$/d' conf/mysql.cfg | grep -n '^install_dir'|awk -F '=' '/install_dir/ {print $2}')
    install_dir=${install_dir:-/opt}
    system_group=$(sed -E '/^#.*|^ *$/d' conf/mysql.cfg | grep -n '^user_group'|awk -F '=' '/user_group/ {print $2}')
    system_group=${user_group:-mysql}
    system_user=$(sed -E '/^#.*|^ *$/d' conf/mysql.cfg | grep -n '^mysql_user'|awk -F '=' '/mysql_user/ {print $2}')
    system_user=${mysql_user:-mysql}
    system_passwd=$(sed -E '/^#.*|^ *$/d' conf/mysql.cfg | grep -n '^mysql_passwd'|awk -F '=' '/mysql_passwd/ {print $2}')
    system_passwd=${mysql_passwd:-mysql}

    # 判断mysql目录是否存在
    if [[ ! -d "$install_dir/mysql-8.0.22" ]]; then
        echo `sudo tar -zxvf $packdir -C $install_dir`
        `sudo mv $install_dir/mysql-8.0.22-el7-x86_64 $install_dir/mysql-8.0.22`
    else
        echo "$install_dir/mysql-8.0.22 exists"
    fi

    # 判断系统用户组是否存在,不存在则创建
    if [[ `egrep "^$system_group" /etc/group` = "" ]]; then
        `sudo groupadd $system_group`
        echo "The $system_group group is created successfully."
    fi

    # 判断用户是否存在,不存在则创建
    if [[ `egrep "^$system_user" /etc/passwd` = "" ]]; then
        `sudo useradd -g $system_group $system_user`
        echo `echo "$system_passwd" | sudo passwd --stdin $system_user`
        echo "The $system_user user is created successfully."
    fi
    `sudo chown -R $system_user:$system_group $install_dir/mysql-8.0.22`


    listIniKeys conf/mysql.cfg client /etc/my.cnf
    listIniKeys conf/mysql.cfg mysqld /etc/my.cnf
    listIniKeys conf/mysql.cfg mysqld_safe /etc/my.cnf
    listIniKeys conf/mysql.cfg mysql /etc/my.cnf

    datadir=$(grep ^" *"datadir /tmp/my.cfg | awk -F '=' '{print $2}')
    log_error=$(grep ^" *"log-error /tmp/my.cfg |awk -F '=' '{print $2}')
    pid_file=$(grep ^" *"pid-file /tmp/my.cfg |awk -F '=' '{print $2}')
    basedir=$(grep ^" *"basedir /tmp/my.cfg |awk -F '=' '{print $2}')

    # 判断数据目录是否存在,不存在则创建
    if [[ ! -d $datadir ]]; then
        `sudo mkdir -p $datadir`
        `sudo chown -R $system_user:$system_group $datadir`
    fi

    # 判断日志目录是否存在,不存在则创建
    log_dir=${log_error%/*}
    if [[ ! -d $log_dir ]]; then
        `sudo mkdir -p $log_dir`
        `sudo touch $log_error`
        `sudo chown -R $system_user:$system_group $log_dir`
    fi

    # 判断pid目录是否存在,不存在则创建
    pid_dir=${pid_file%/*}
    if [[ ! -d $pid_dir ]]; then
        `sudo mkdir -p $pid_dir`
        `sudo chown -R $system_user:$system_group $pid_dir`
    fi

    # 初始化mysql
    if [[ `$datadir | wc -w` == 0 ]]; then
        `sudo sh -c ''$install_dir'/mysql-8.0.22/bin/mysqld --initialize --user='$system_user' --basedir='$basedir' --datadir='$datadir' > '$log_dir'/init.log 2>&1'`
    
        #`sudo $install_dir/mysql-8.0.22/bin/mysqld --initialize --user=$mysql_user --basedir=$basedir --datadir=$datadir`
        # 创建软连接
        if [ ! -f "/usr/bin/mysql" ]; then
            `sudo ln -s $install_dir/mysql-8.0.22/bin/mysql /usr/bin`
        fi
        # 添加MySQL启动脚本到系统服务
        if [ ! -f "/etc/init.d/mysqld/mysql.server" ]; then
            `sudo cp $install_dir/mysql-8.0.22/support-files/mysql.server /etc/init.d/mysqld`
            `sudo chmod 755 /etc/init.d/mysqld`
        fi

        echo `sudo service mysqld restart`
    
        init_password=$(sudo awk -F ': ' '{print $2}' $log_dir/init.log | sed '/^$/d')
        passwd=$(grep ^" *"mysql_passwd conf/mysql.cfg |awk -F '=' '{print $2}')

        # 修改密码
        `$install_dir/mysql-8.0.22/bin/mysqladmin -uroot -p"$init_password" password $passwd`

        # 开启远程访问
        `mysql -uroot -p$passwd mysql -e "update user set host='%' where user='root'"`
        `mysql -uroot -p$passwd mysql -e "flush privileges"`
    else
        echo `sudo service mysqld restart`
    fi
}
install_mysql
