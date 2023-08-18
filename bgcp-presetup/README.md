# Presetup



## Usage

​    This project is suitable for pre-processing servers before deployment. You can perform preset processing by using the following command:

```shell
cd presetup
bin/bootstrap.sh
```

​     ① The script of `bootstrap.sh` is used to execute a series of pipeline tasks. It is a bootstrap program, and each specific operation is defined in the `sbin` directory.

​     ② Each script in the `sbin` directory represents a separate execution unit in a pipeline and can be run independently.

​     ③ The specific behavior of executing preset processing can be uniformly configured according to the `conf/setup.yaml` configuration file.



## Features

​      The responsibilities of each execution unit under the sbin directory are as follows:

| Script Name | Description                                                  |
| ----------- | ------------------------------------------------------------ |
| user.sh     | Deploy User Super Administrator Configuration.               |
| hostname.sh | Service domain name and IP address mapping relationship.     |
| ssh.sh      | SSH server to server password free login.                    |
| kernel.sh   | Language Environment Installation, e.g. limit and sysctl etc. |
| jdk.sh      | Language Environment Installation, e.g. JDK etc.             |



## Note

​	① Priority should be given to installing the `yq` parsing library when using it, The installation method is as follows: 

```shell
mkdir -p yq_linux_amd64 && tar -zxvf yq_linux_amd64.tar.gz -C ./yq_linux_amd64
mv ./yq_linux_amd64/yq_linux_amd64 ./yq_linux_amd64/yq && cp ./yq_linux_amd64/yq /usr/bin/ && chmod +x /usr/bin/yq
rm -rf ./yq_linux_amd64
```

​		`yq` package url refer to [yq](https://github.com/mikefarah/yq/releases). 

​    ② All executable files for this project must be executed under root user.