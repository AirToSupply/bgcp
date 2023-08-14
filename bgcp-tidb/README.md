# TiUP

​		This project is a bootstrapper for `TiDB` to install and deploy the component `TiUP`.



## Usage

【step-1】Specify TiDB related configurations in configuration `conf/topology.yaml`, such as the configuration of various components and engine parameters in TiDB.

【step-2】Specify the relevant configuration of tiup and the basic parameters of TiDB in configuration `conf/setup.yaml`, such as TiDB system parameters and connection information.

【step-3】Execute the following command to install `tiup`：

```shell
bin/bootstrap.sh
```

【step-4】Complete TIDB cluster boot and initialization：

​		① Check and repair the environment.

```shell
bin/runc.sh check
bin/runc.sh check-apply
bin/runc.sh check
```

​		② Deploying and installing TiDB related components.

```shell
bin/runc.sh deploy
```

​		③ View the list of each component.

```shell
bin/runc.sh display
```

​        ④ Initializing TiDB cluster.

```shell
bin/runc.sh init
```

​		⑤ Starting the TiDB cluster.

```shell
bin/runc.sh start
```

【step-5】 Connect TiDB Server. Select option **1** from the prompted interactive options.

```shell
bin/client.sh
```



## Note

​	① Priority should be given to installing the `yq` parsing library when using it. The installation method is as follows: 

```shell
mkdir -p yq_linux_amd64 && tar -zxvf yq_linux_amd64.tar.gz -C ./yq_linux_amd64
mv ./yq_linux_amd64/yq_linux_amd64 ./yq_linux_amd64/yq && cp ./yq_linux_amd64/yq /usr/bin/ && chmod +x /usr/bin/yq
rm -rf ./yq_linux_amd64
```

​		`yq` package url refer to [yq](https://github.com/mikefarah/yq/releases). 

​     ② All executable files for this project must be executed under `global.user` in `conf/topology.yaml`，and this user own `sudo` permission.

​	 ③ File `bin/runc.sh` encapsulates some commonly used functions in the up cluster command, and you can view the specific usage methods through the following command.

​     ④ File `bin/client.sh` provides a shortcut to connect to the TiDB server, as well as modifying and refreshing TiDB system parameters.