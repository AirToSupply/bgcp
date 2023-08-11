#!/bin/bash

gcc --version
if [ $? != 0 ]; then
    echo `sudo rpm -Uvh gcc/*.rpm --nodeps --force`
fi

# 获取 Nginx 安装包
nginx_package=$(sed -E '/^#.*|^ *$/d' conf/nginx.cfg | grep -n '^nginx_package' |awk -F '=' '/nginx_package/ {print $2}')
# 获取 Nginx 安装包目录
nginx_path=${nginx_package%/*}
# 获取 Nginx 安装包名
nginx_pack=${nginx_package##*/}
# 获取 Nginx 目录名
nginx_dir=${nginx_pack%???????}

# 获取 pcre 安装包
pcre_package=$(sed -E '/^#.*|^ *$/d' conf/nginx.cfg | grep -n '^pcre_package' |awk -F '=' '/pcre_package/ {print $2}')
# 获取 pcre 安装包目录
pcre_path=${pcre_package%/*}
# 获取 pcre 安装包名
pcre_pack=${pcre_package##*/}
# 获取 pcre 目录名
pcre_dir=${pcre_pack%???????}

# 获取 zlib 安装包
zlib_package=$(sed -E '/^#.*|^ *$/d' conf/nginx.cfg | grep -n '^zlib_package' |awk -F '=' '/zlib_package/ {print $2}')
# 获取 zlib 安装包目录
zlib_path=${zlib_package%/*}
# 获取 zlib 安装包名
zlib_pack=${zlib_package##*/}
# 获取 zlib 目录名
zlib_dir=${zlib_pack%???????}

# 获取 openssl 安装包
openssl_package=$(sed -E '/^#.*|^ *$/d' conf/nginx.cfg | grep -n '^openssl_package' |awk -F '=' '/openssl_package/ {print $2}')
# 获取 openssl 安装包目录
openssl_path=${openssl_package%/*}
# 获取 openssl 安装包名
openssl_pack=${openssl_package##*/}
# 获取 openssl 目录名
openssl_dir=${openssl_pack%???????}

# 获取安装路径
install_path=$(sed -E '/^#.*|^ *$/d' conf/nginx.cfg | grep -n '^install_path'|awk -F '=' '/install_path/ {print $2}')
install_path=${install_path:-/opt/nginx-1.17.6}

# 离线安装pcore
function install_pcre()
{
    if [[ ! -d "$pack_path/$pcre_dir" ]]; then
        echo `sudo tar -zxvf $pcre_package -C $pack_path`
    fi
    cd $pack_path/$pcre_dir
    echo `sudo ./configure`
    echo `sudo ./make -j 40 && make install`
}

# 离线安装zlib
function install_zlib()
{
    if [[ ! -d "$zlib_path/$zlib_dir" ]]; then
        echo `sudo tar -zxvf $zlib_package -C $zlib_path`
    fi
    cd $zlib_path/$zlib_dir
    echo `sudo ./configure`
    echo `sudo ./make -j 40 && make install`
}

# 离线安装openssl
function install_openssl()
{
    if [[ ! -d "$openssl_path/$openssl_dir" ]]; then
        echo `sudo tar -zxvf $openssl_package -C $openssl_path`
    fi
    cd $openssl_path/$openssl_dir
    echo `sudo ./configure`
    echo `sudo ./make -j 40 && make install`
}

# 离线安装nginx
function install_nginx()
{
    install_pcre
    install_zlib
    install_openssl

    if [[ ! -d "$nginx_path/$nginx_dir" ]]; then
        echo `sudo tar -zxvf $nginx_package -C $install_path`
    fi
    cd $nginx_path/$nginx_dir
    echo `sudo ./configure --prefix='$install_path' --with-http_ssl_module --with-pcre='$install_dir/$pcre_dir' --with-zlib='$install_dir/$zlib_dir' --with-openssl='$install_dir/$openssl_dir'`
    echo `sudo ./make -j 40 && make install`
}

install_nginx

# 启动Nginx
function start_nginx()
{
    if [[ `ps -ef | grep nginx | wc -l` == 1 ]]; then
        $install_path/sbin/nginx
        if [[ `ps -ef | grep nginx | wc -l` > 1 ]]; then
            echo "Nginx 启动成功"
            if [[ -d "$pack_path/$pcre_dir" ]]; then
                `sudo rm -rf $pack_path/$pcre_dir`
            fi

            if [[ -d "$zlib_path/$zlib_dir" ]]; then
                `sudo rm -rf $zlib_path/$zlib_dir`
            fi

            if [[ ! -d "$openssl_path/$openssl_dir" ]]; then
                `sudo rm -rf $openssl_path/$openssl_dir`
            fi
        else
            echo "Nginx 启动失败"
        fi
    fi
}

start_nginx
