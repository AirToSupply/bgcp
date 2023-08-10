#!/bin/bash

inifile="$1"
section="$2"
configurationfile="$3"

if [ $# -ne 3 ] || [ ! -f ${inifile} ];then
    echo  "ini file not exist!"
    exit
else
    keys=$(sed -E '/^#|^$/d' $inifile| awk '/\['$section'\]/{f=1;next} /\[*\]/{f=0} f'|awk -F'=' '{print $1}')
    IFS=$'\n'

    while read -r i;
    do
        key=$i
        value=`sed -E '/^#|^$/d' $inifile | awk -F '=' '/\['$section'\]/{a=1}a==1&&$1~/'$key'/{print $2;exit}' $inifile`

        conf=$(grep -Ev '^$|^#' $configurationfile)
        if [[ -n $key ]] && [[ `echo $conf | grep "$key"` != "" ]]; then
            k=`grep ^" *"$key $configurationfile | awk -F ':' '{print $1}'`
            sed -i "s#^$k.*#$k:${value}#g" $configurationfile
        elif [[ -n $key ]] && [[ `echo $conf | grep "$key"` = "" ]]; then
            echo $key:$value >> $configurationfile
        fi
    done <<< "$keys"
fi
