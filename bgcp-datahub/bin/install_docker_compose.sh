#! /bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
LIB_DIR=`cd ${WORK_DIR};cd ../lib;pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/docker_compose.cfg


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
deploy_user=$(sed -r -n 's/(^deploy_user=)(.*)$/\2/p' $CONF_FILE)

# [docker-compose_tmp_path]
docker_compose_tmp_dir=$(sed -r -n 's/(^docker_compose_tmp_dir=)(.*)$/\2/p' $CONF_FILE)

# [docker-compose_install_path]
docker_compose_install_dir=$(sed -r -n 's/(^docker_compose_install_dir=)(.*)$/\2/p' $CONF_FILE)
docker_compose_install_name=$(sed -r -n 's/(^docker_compose_install_name=)(.*)$/\2/p' $CONF_FILE)
docker_compose_install_ln=$(sed -r -n 's/(^docker_compose_install_ln=)(.*)$/\2/p' $CONF_FILE)


# ---------------------------------------------------------------------------
# step-1: docker-compose install
# ---------------------------------------------------------------------------
docker_compose_tmp_path=${docker_compose_tmp_dir%/*}
docker_compose_tmp_name=${docker_compose_tmp_dir##*/}

docker_compose_wc=$(ls $docker_compose_install_dir | grep "$docker_compose_install_name$" | wc -l)
if [ $docker_compose_wc -eq 0 ]; then
    cd $docker_compose_tmp_path
    cp $docker_compose_tmp_name $docker_compose_install_dir/
    cd $docker_compose_install_dir/
    mv $docker_compose_tmp_name $docker_compose_install_name
    sudo chmod +x $docker_compose_install_dir/$docker_compose_install_name

    echo -e "\033[34m [step-1: docker-compose install ] Docker-compose installed successfully! \033[0m"
else
    echo -e "\033[33m [step-1: docker-compose install ] Docker-compose has been installed! \033[0m"
fi


# ---------------------------------------------------------------------------
# step-2: docker-compose creates soft links
# ---------------------------------------------------------------------------

docker_compose_ln=$(ls /usr/bin | grep "$docker_compose_install_name" | wc -l)
if [ $docker_compose_ln -eq 0 ]; then
    ln -s $docker_compose_install_dir/$docker_compose_install_name $docker_compose_install_ln

    echo -e "\033[34m [step-2: docker-compose creates soft links ] Soft link created successfully! \033[0m"
else
    echo -e "\033[33m [step-2: docker-compose creates soft links ] Soft link already exists! \033[0m"
fi
