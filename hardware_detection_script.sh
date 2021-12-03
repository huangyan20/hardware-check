#!/bin/bash
#cpu，mem，network，NVIDIA信息收集
function hardware_cpu_mem_network_NVIDIA() {
    #根据实际情况改动hosts，根据ansible分组进行区分操作系统这里默认使用all
    #cpu检测输出至文件
    ansible all -m shell -a 'lscpu |grep -aE "Model name|Socket" |sed s/[[:space:]]//g' >> cpu_info.txt
    #总内存检测输出至文件
    ansible all -m shell -a 'free -hm |sed s/[[:space:]]//g|grep Mem| cut -d 'G' -f 1' >> total_memory_info.txt
    #网卡检测输出至文件
    ansible all -m shell -a 'lshw -C net|grep -aE "logical name" |awk "{print \$3}" |xargs -I "{}" ethtool {}|grep -aE "Settings|Speed"' >> network_card_info.txt
    #收集显卡信息，有几张显卡
    ansible all -m shell -a 'nvidia-smi -q|grep -aE "Attached GPUs"|sed s/[[:space:]]//g' >> numb_gpu_info.txt
    #收集nvidia-smi结果输出
    ansible all -m shell -a 'nvidia-smi' >> GPU_info.txt
}

#ubuntu配置DNS
function set_DNS() {
     sed -i 's/#DNS=/DNS=114.114.114.114/g' /etc/systemd/resolved.conf
     mv /etc/resolv.conf /etc/resolv.conf.bak
     ln -s /run/systemd/resolve/resolv.conf /etc/
     systemctl restart systemd-resolved
     apt update
     apt install ansible -y
}

#检测是否安装显卡驱动并且调用收集函数
function  start_collect() {
     if ! type nvidia-smi; then
          echo "---未安装驱动，请手动安装命令：ansible-playbook install_GPU_driver"
     else
          echo "---已经安装显卡驱动"
          echo "---开始收集cpu，内存，网卡，显卡信息到文件cpu_info.txt，total_memory_info.txt，network_card_info.txt，numb_gpu_info.txt，GPU_info.txt"
          #收集
          hardware_cpu_mem_network_NVIDIA
     fi
}

function install_fail() {
     echo "---未安装成功"
     echo "---检查网络原因---"
}

function install_success_collect() {
     echo "---开始检查显卡驱动,并且收集数据"
     start_collect
}

function analysis_result() {
     echo "$1" # arguments are accessible through $1, $2,...
}


hostname=$(hostnamectl |grep -a 'Operating System'|awk '{print tolower($3)}')
if [ $hostname = 'ubuntu' ]; then
     echo "---操作系统为：${hostname}"
     echo "---开始检测是否安装ansible"
     if ! type ansible; then
          echo "---未安装ansible，现在开始安装"
          #-c表示次数，-w表示time out时间，单位秒
          if ping -c 1 -w 1 www.baidu.com; then
               echo "---网络正常,开始安装"
               apt update
               apt install ansible -y
               if ! type ansible; then
                    install_fail
               else
                    install_success_collect
                    echo "---分析数据"
                    echo "删除驱动"
               fi
          else
               echo "---网络不正常,配置DNS，安装"
               set_DNS
               if ! type ansible; then
                    install_fail
               else
                    install_success_collect
                    echo "---分析数据"
                    echo "删除驱动"
               fi
          fi
     else
          echo "---ansible已安装成功"
          install_success_collect
          echo "---分析数据"
          echo "删除驱动"
     fi

elif [ $hostname = 'centos' ]; then
     echo $hostname
else
     echo $hostname
     echo "New Operating system! please add again"
fi






