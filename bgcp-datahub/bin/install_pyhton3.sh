#! /bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
LIB_DIR=`cd ${WORK_DIR};cd ../lib;pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/python.cfg


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
deploy_user=$(sed -r -n 's/(^deploy_user=)(.*)$/\2/p' $CONF_FILE)

# [openssl_tmp_path]
openssl_tmp_package_dir=$(sed -r -n 's/(^openssl_tmp_package_dir=)(.*)$/\2/p' $CONF_FILE)
openssl_unzip_dir_name=$(sed -r -n 's/(^openssl_unzip_dir_name=)(.*)$/\2/p' $CONF_FILE)

# [openssl_install_path]
openssl_install_path=$(sed -r -n 's/(^openssl_path=)(.*)$/\2/p' $CONF_FILE)

# [python_tmp_path]
python_tmp_package_dir=$(sed -r -n 's/(^python_tmp_package_dir=)(.*)$/\2/p' $CONF_FILE)
python_unzip_dir_name=$(sed -r -n 's/(^python_unzip_dir_name=)(.*)$/\2/p' $CONF_FILE)
python_tmp_rpm_dir=$(sed -r -n 's/(^python_tmp_rpm_dir=)(.*)$/\2/p' $CONF_FILE)

# [python_install_path]
python_install_rpm_dir=$(sed -r -n 's/(^python_install_rpm_dir=)(.*)$/\2/p' $CONF_FILE)
python_prefix_path=$(sed -r -n 's/(^python_path=)(.*)$/\2/p' $CONF_FILE)


# ---------------------------------------------------------------------------
# step-1: Unzip and install openssl
# ---------------------------------------------------------------------------
openssl_package_tmp_path=${openssl_tmp_package_dir%/*}
openssl_package_jar_name=${openssl_tmp_package_dir##*/}

cd $openssl_package_tmp_path
if [ ! -d $openssl_unzip_dir_name ]; then
    tar -zxvf $openssl_package_jar_name
    echo -e "\033[34m [step-1: Unzip and install openssl] openssl successfully decompressed! \033[0m"
else
    echo -e "\033[33m [step-1: Unzip and install openssl] openssl has been decompressed! \033[0m"
fi


openssl_install_path_wc=$(ls $openssl_install_path/ | wc -l)
if [ $openssl_install_path_wc -eq 0 ]; then
    mkdir $openssl_install_path
    cd $openssl_package_tmp_path
    chown -R $deploy_user:$deploy_user $openssl_unzip_dir_name
    cd $openssl_unzip_dir_name
    ./config --prefix=$openssl_install_path
    make && make install

    echo -e "\033[34m [step-1.2: Unzip and install openssl ] openssl successfully installed! \033[0m"
else
    echo -e "\033[33m [step-1.2: Unzip and install openssl ] openssl has been installed! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-2: Create openssl soft connection
# ---------------------------------------------------------------------------
opensssl_soft_link=$(ll /usr/bin/openssl | grep "$openssl_install_path" | wc -l)
if [ $python_soft_link -eq 0 ]; then
    rm -rf /usr/bin/openssl
    ln -s $openssl_install_path/bin/openssl /usr/bin/openssl

    echo -e "\033[34m [step-2: Create openssl soft connection ] The openssl soft link was created successfully! \033[0m"
else
    echo -e "\033[33m [step-2: Create openssl soft connection ] openssl soft link already exists! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-3: Configure openssl file
# ---------------------------------------------------------------------------
openssl_so_conf=$(cat /etc/ld.so.conf | grep "^$openssl_install_path" | wc -l)
if [ $openssl_so_conf -eq 0 ]; then
    echo "$openssl_install_path/lib " >> /etc/ld.so.conf

    echo -e "\033[34m [step-3.1: Configure openssl file ] Configuration file modified successfully! \033[0m"
else
    echo -e "\033[33m [step-3.1: Configure openssl file ] The configuration file has been modified! \033[0m"
fi


source ~/.bash_profile
openssl_path_value=$(cat ~/.bash_profile | grep '^export LD_LIBRARY_PATH=')
if [ -z "$openssl_path_value" ];then
    echo -e "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$openssl_install_path/lib"        >> ~/.bash_profile
    sleep 1s
    source ~/.bash_profile
    echo -e "\033[34m [step-3.2: Configure openssl environment variables] has injected \$LD_LIBRARY_PATH successfully! \033[0m"
else
    echo -e "\033[33m [step-3.2: Configure openssl environment variables] \$LD_LIBRARY_PATH has been already existed! \033[0m"
fi
source ~/.bash_profile



# ---------------------------------------------------------------------------
# step-4: Install python dependencies
# ---------------------------------------------------------------------------
if [ ! -d $python_install_rpm_dir ]; then
	mkdir -p $python_install_rpm_dir
	chown -R $deploy_user:$deploy_user $python_install_rpm_dir

    echo -e "\033[34m [step-4.1: Python depends on the installation directory ] Directory created successfully! \033[0m"
else
    echo -e "\033[31m [step-4.1: Python depends on the installation directory ] directory has been created! \033[0m"
fi

bzip2_devel=$(rpm -qa bzip2-devel | wc -l)
if [ $bzip2_devel -eq 0 ]; then
	cp $python_tmp_rpm_dir/* $python_install_rpm_dir/
	cd $python_install_rpm_dir
	rpm -Uvh ./*.rpm --nodeps --force

    echo -e "\033[34m [step-4.2: Load Python dependencies ] Dependency loaded successfully! \033[0m"
else
    echo -e "\033[33m [step-4.2: Load Python dependencies ] Dependency loading has been loaded! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-5: Unzip and install python3
# ---------------------------------------------------------------------------
python_package_tmp_path=${python_tmp_package_dir%/*}   # /tmp/datahub/lib/python
python_package_jar_name=${python_tmp_package_dir##*/}  # Python-3.8.3.tgz

cd $python_package_tmp_path
if [ ! -d $python_unzip_dir_name ]; then
    tar -zxvf $python_package_jar_name
    echo -e "\033[34m [step-5.1: Unzip and install python3 ] python3 successfully decompressed! \033[0m"
else
    echo -e "\033[33m [step-5.1: Unzip and install python3 ] python3 has been decompressed! \033[0m"
fi


python_path_count=$(ls $python_prefix_path/ | wc -l)
if [ $python_path_count -eq 0 ]; then
    mkdir $python_prefix_path
    chown -R $deploy_user:$deploy_user $python_unzip_dir_name
    cd $python_unzip_dir_name
    ./configure --prefix=$python_prefix_path --with-openssl=$openssl_install_path --with-openssl-rpath=auto
    make && make install
    echo -e "\033[34m [step-5.2: Unzip and install python3 ] python3 successfully installed! \033[0m"
else
    echo -e "\033[33m [step-5.2: Unzip and install python3 ] python3 has been installed! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-6: Create python3 soft connection
# ---------------------------------------------------------------------------
python_soft_link=$(ls /usr/bin/python3 | wc -l)
if [ $python_soft_link -eq 0 ]; then
    ln -s $python_prefix_path/bin/python3 /usr/bin/python3
    ln -s $python_prefix_path/bin/pip3 /usr/bin/pip3

    echo -e "\033[34m [step-6: Unzip and install python3 ] The python3 soft link was created successfully! \033[0m"
else
    echo -e "\033[33m [step-6: Create python3 soft connection ] python3 soft link already exists! \033[0m"
fi

