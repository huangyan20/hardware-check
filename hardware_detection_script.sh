#!/bin/bash
#信息收集函数
function hardware_cpu_mem_nework {
    #根据实际情况改动hosts
    #cpu检测输出至文件
    ansible all -m shell -a 'lscpu |grep -aE "Model name|Socket" |sed s/[[:space:]]//g' >> cpu_info.txt
    #总内存检测输出至文件
    ansible all -m shell -a 'free -hm |sed s/[[:space:]]//g|grep Mem| cut -d 'G' -f 1' >> total_memory_info.txt
    #网卡检测输出至文件
    ansible all -m shell -a 'lspci |grep Ether' >> network_card_info.txt
}

#显卡主机信息收集，不同版本的操作系统，安装方式不一样
function NVIDIA_system_info {
    #收集各个系统的类型
    ansible all -m shell -a 'hostnamectl |grep -aE "Operating System"' >> diff_system_type.txt
}

#显卡信息收集
function NVIDIA_info {
    echo
}

hostname=$(hostnamectl |grep -a 'Operating System'|awk '{print tolower($3)}')
if [ $hostname = 'ubuntu' ]; then
     echo "---操作系统为：${hostname}"
     echo "---开始检测是否安装ansible"
     if ! type ansible; then
          echo "---未安装ansible，现在开始安装"
          #-c表示次数，-w表示time out时间，单位秒
          if ping -c 1 -w 1 www.baidu.com; then
               echo "---网络正常,安装"
               apt update
               apt install ansible -y
               if ! type ansible; then
                    echo "---未安装成功"
                    echo "---检查网络原因---"
               else
                    echo "---已安装成功"
                    echo "开始收集cpu，内存，网卡信息到文件cpu_info.txt，total_memory_info.txt，network_card_info.txt"
                    #信息收集函数调用
                    hardware_cpu_mem_nework
               fi
          else
               echo "---网络不正常,配置DNS，安装"
               sed -i 's/#DNS=/DNS=114.114.114.114/g' /etc/systemd/resolved.conf
               mv /etc/resolv.conf /etc/resolv.conf.bak
               ln -s /run/systemd/resolve/resolv.conf /etc/
               systemctl restart systemd-resolved
               apt update
               apt install ansible -y
               if ! type ansible; then
                    echo "---未安装成功"
                    echo "---检查网络原因---"
               else
                    echo "---已安装成功"
                    echo "---开始收集cpu，内存，网卡信息到文件cpu_info.txt，total_memory_info.txt，network_card_info.txt"
                    #信息收集函数调用
                    hardware_cpu_mem_nework
               fi
          fi
     else
          echo "---已安装ansible"
          echo "---开始收集cpu，内存，网卡信息到文件cpu_info.txt，total_memory_info.txt，network_card_info.txt"
          #信息收集函数调用
          hardware_cpu_mem_nework
          echo "---已收集cpu,mem,network"
          #检测是哪个类型的系统，不同类型系统显卡安装方式不同
          NVIDIA_system_info
          #分析系统类型分类ubuntu，centos等
          
     fi
     
elif [ $hostname = 'centos' ]; then
     echo $hostname
else
     echo $hostname
     echo "New Operating system! please add again"
fi






