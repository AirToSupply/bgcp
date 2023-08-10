#! /bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
LIB_DIR=`cd ${WORK_DIR};cd ../lib;pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/datahub.cfg


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
deploy_user=$(sed -r -n 's/(^deploy_user=)(.*)$/\2/p' $CONF_FILE)
service_hosts=$(sed -r -n 's/(^service_hosts=)(.*)$/\2/p' $CONF_FILE)

# [datahub_tmp_path]
datahub_package_tmp_dir=$(sed -r -n 's/(^datahub_package_tmp_dir=)(.*)$/\2/p' $CONF_FILE)
datahub_upgrade_tmp=$(sed -r -n 's/(^datahub_upgrade_tmp=)(.*)$/\2/p' $CONF_FILE)
datahub_docker_image_dir=$(sed -r -n 's/(^datahub_docker_image_dir=)(.*)$/\2/p' $CONF_FILE)
datahub_pyhton_upgrade_tmp_dir=$(sed -r -n 's/(^datahub_pyhton_upgrade_tmp_dir=)(.*)$/\2/p' $CONF_FILE)

# [datahub_install_path]
datahub_install_package_dir=$(sed -r -n 's/(^datahub_install_package_dir=)(.*)$/\2/p' $CONF_FILE)
datahub_version=$(sed -r -n 's/(^datahub_version=)(.*)$/\2/p' $CONF_FILE)
datahub_upgrade_dir=$(sed -r -n 's/(^datahub_upgrade_dir=)(.*)$/\2/p' $CONF_FILE)
datahub_pyhton_upgrade_install=$(sed -r -n 's/(^datahub_pyhton_upgrade_install=)(.*)$/\2/p' $CONF_FILE)



# ---------------------------------------------------------------------------
# step-1: Environment detection of pyhton, docker, docker-compose before datahub installation
# ---------------------------------------------------------------------------
python3_ver=$(python3 -V | awk '{print $2}' | awk -F '.' '{print $1}')
if [[ "$python3_ver" == "3" ]]; then
    echo -e "\033[33m [step-1.1 : detect python3 ] python3 is already installed！\033[0m"
else
    chmod +x $WORK_DIR/install_pyhton3.sh
    sh $WORK_DIR/install_pyhton3.sh
    echo -e "\033[34m [step-1.1 : detect python3 ]  python3 installed successfully ! \033[0m"
fi

docker_ver=$(docker version | grep "^ API version:" | awk '{print $3}')
if [[  "$docker_ver" != "" ]]; then
    if [[ "$docker_ver" > "1.40"  ]]; then
    	echo -e "\033[33m [step-1.2 : detect docker ] docker is already installed！\033[0m"
    else
        echo -e "\033[31m [step-1.2 : detect docker ]  The docker version is too low, please install docker with API version 1.40 or higher ! \033[0m"
        exit 0
    fi
else
    echo -e "\033[31m [step-1.2 : detect docker ]  Please install docker ! \033[0m"
    exit 0
fi


docker_compose_ver=$(docker-compose version | awk '{print $4}' | awk -F '.' '{print $1}')
if [[  "$docker_compose_ver" != ""  ]]; then
    if [[ "$docker_compose_ver" == "v2"  ]]; then
    	echo -e "\033[33m [step-1.2 : detect docker-compose ] Docker-compos is already installed！\033[0m"
    else
        echo -e "\033[31m [step-1.2 : detect docker-compose ] The docker-compose version is too low, Please install docker-compose version 2.x.x ! \033[0m"
        exit 0
    fi
else
	echo -e "\033[34m [step-1.3 : detect docker-compose ]  Start installing docker-compose! \033[0m"
	chmod +x $WORK_DIR/install_docker_compose.sh
	sh $WORK_DIR/install_docker_compose.sh
    echo -e "\033[34m [step-1.3 : detect docker-compose ]  Docker-compose installed successfully ! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-2: upgrade pip 、 wheel 、 setuptools
# ---------------------------------------------------------------------------
pip_version=$(pip3 list | grep pip | awk '{print $2}')
if [[ "$pip_version" == "23.1.2" ]]; then
    echo -e "\033[33m [step-2: upgrade pip、 wheel、 setuptools ]  pip 、 wheel 、 setuptools has been upgraded! \033[0m"
else
    mkdir $datahub_pyhton_upgrade_install
    cp $datahub_pyhton_upgrade_tmp_dir/* $datahub_pyhton_upgrade_install/
    cd $datahub_pyhton_upgrade_install
    python3 -m pip install --upgrade pip-23.1.2-py3-none-any.whl
    python3 -m pip install --upgrade wheel-0.40.0-py3-none-any.whl
    python3 -m pip install --upgrade setuptools-67.8.0-py3-none-any.whl
    echo -e "\033[34m [step-2: Unzip and install python3 ]  pip 、 wheel 、 setuptools upgrade successful! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-3: Datahub offline package installation
# ---------------------------------------------------------------------------
if [ ! -d $datahub_install_package_dir ];then
	mkdir -p $datahub_install_package_dir
	chown -R $deploy_user:$deploy_user $datahub_install_package_dir
	cp $datahub_package_tmp_dir/* $datahub_install_package_dir/
	cd $datahub_install_package_dir
	pip3 install --no-index --find-links=$datahub_install_package_dir acryl-datahub==$datahub_version -i  https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host pypi.tuna.tsinghua.edu.cn

    datahub_ver=$(python3 -m datahub version | grep "DataHub CLI version" |awk -F ':' '{print $2}')
    if [ $datahub_ver == $datahub_version ]; then
        echo -e "\033[34m [step-3: Datahub offline package installation ] Datahub offline package successful installation! \033[0m"
    else
        echo -e "\033[34m [step-3: Datahub offline package installation ] Datahub offline package installation fails! \033[0m"
        exit 0
    fi
else
    echo -e "\033[33m [step-3: Datahub offline package installation ] The datahub offline package has been installed! \033[0m"
fi

# ---------------------------------------------------------------------------
# step-4: update dependencies
# ---------------------------------------------------------------------------

if [ ! -d $datahub_upgrade_dir ];then
	mkdir -p $datahub_upgrade_dir
	chown -R $deploy_user:$deploy_user $datahub_upgrade_dir
	cp $datahub_upgrade_tmp/* $datahub_upgrade_dir/
	cd $datahub_upgrade_dir
	python3 -m pip install --upgrade certifi-2023.5.7-py3-none-any.whl
    python3 -m pip install --upgrade charset_normalizer-2.1.1-py3-none-any.whl
    python3 -m pip install --upgrade idna-3.4-py3-none-any.whl
    python3 -m pip install --upgrade requests-2.28.1-py3-none-any.whl
    python3 -m pip install --upgrade urllib3-1.26.16-py2.py3-none-any.whl

    echo -e "\033[34m [step-4: update dependencies ] Datahub offline package update completed! \033[0m"
else
    echo -e "\033[33m [step-4: update dependencies ] Datahub offline package has been updated! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-5: Load the datahub docker image package
# ---------------------------------------------------------------------------
datahub_front_reacrt_image=$(docker images -q "linkedin/datahub-frontend-react")
if [[ $datahub_front_reacrt_image == "" ]];then
	cd  $datahub_docker_image_dir
    docker load -i cp-schema-registry-7.2.2.tar
    docker load -i cp-zookeeper-7.2.2.tar
    docker load -i datahub-actions-0.10.3.tar
    docker load -i datahub-elasticsearch-setup-0.10.3.tar
    docker load -i datahub-frontend-react-0.10.3.tar
    docker load -i datahub-gms-0.10.3.tar
    docker load -i datahub-kafka-setup-0.10.3.tar
    docker load -i datahub-mysql-setup-0.10.3.tar
    docker load -i datahub-upgrade-0.10.3.tar
    docker load -i elasticsearch-7.10.1.tar
    docker load -i kafka-7.2.2.tar
    docker load -i mysql-5.7.tar

    datahub_image_cont=$(docker images | grep "0.10.3" | wc -l)
    if [ $datahub_image_cont -eq 7 ];then
        echo -e "\033[34m [step-5: Load the datahub docker image package] Image package loaded successfully! \033[0m"
    else
        echo -e "\033[33m [step-5: Load the datahub docker image package] Image package failed to load! \033[0m"
    fi
else
    echo -e "\033[33m [step-5: Load the datahub docker image package] The image package has been loaded! \033[0m"
fi



# ---------------------------------------------------------------------------
# step-6: start datahub
# ---------------------------------------------------------------------------
datahub_port_web_count=$(netstat -tunlp | grep 9002 | wc -l)
if [ $datahub_port_web_count -eq 0 ];then
    cp  $datahub_docker_image_dir/docker-compose-without-neo4j.quickstart.yml $datahub_upgrade_dir/../

    datahub_port_conflicts=""
    datahub_gms_port=""
    mysql_port_count=$(netstat -tunlp | grep 3306 | wc -l)
    if [ $mysql_port_count -ne 0 ]; then
        datahub_port_conflicts="--mysql-port 53306 "
    fi

    zk_port_count=$(netstat -tunlp | grep 2181 | wc -l)
    if [ $zk_port_count -ne 0 ]; then
        datahub_port_conflicts=$datahub_port_conflicts"--zk-port 52181 "
    fi

    zk_serverPort_count=$(netstat -tunlp | grep 8080 | wc -l)
    if [ $zk_serverPort_count -ne 0 ]; then
        datahub_gms_port="DATAHUB_MAPPED_GMS_PORT=58080"
    fi

    cd $datahub_upgrade_dir/../
    touch datahub-start.sh
    echo "${datahub_gms_port} python3 -m datahub docker quickstart -f ./docker-compose-without-neo4j.quickstart.yml $datahub_port_conflicts" >> datahub-start.sh
    chmod +x datahub-start.sh
    sh  datahub-start.sh

    echo -e "\033[34m [step-6: start datahub] Datahub started successfully! \033[0m"
else
    echo -e "\033[33m [step-6: start datahub] Datahub has started! \033[0m"
fi
