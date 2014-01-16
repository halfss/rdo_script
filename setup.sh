#!/bin/bash
# check user
if [ `whoami` != 'root' ];then
    echo "please use root to exec this script"
    exit 0
fi

cd `dirname $0`

#source env
if [ -f "rdo.rc" ];then
    source ./rdo.rc
else
    echo "not rdo.rc file"
    exit 0 
fi


#set ssh key
if [ ! -d ~/.ssh ];then
    mkdir ~/.ssh
fi
if [ ! -f ~/.ssh/id_rsa ];then
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi

key_file=`cat ~/.ssh/id_rsa.pub`

remote_cmd="mkdir ~/.ssh;
            setenforce 0;
            cat ~/.ssh/authorized_keys | grep '$key_file' || echo '$key_file' >> ~/.ssh/authorized_keys"

if [ "$CONFIG_USE_EPEL" = 'n' ];then
    add_repo="ls /etc/yum.repos.d/ | grep back || find /etc/yum.repos.d/ -name \*.repo |xargs -n 1 -i mv "{}" "{}_back";
            yum install -y http://mirrors.halfss.com/halfss-mirrors-0.01-1.noarch.rpm"
    remote_cmd=$add_repo";"$remote_cmd
fi

if [ -n "$EXTER_REPO_IP" ];then
    domain=`echo $CONFIG_REPO | awk -F'[/:]' '{print $4}'`
    ext_remote_cmd="cat /etc/hosts |grep '$domain' || echo '$EXTER_REPO_IP   $domain'  >> /etc/hosts"
    remote_cmd=$ext_remote_cmd";"$remote_cmd
fi

host_list=${compute_ip/\,/\ }

for i in $host_list
do
    ssh root@$i -T "$remote_cmd"
done


#clear iptables
echo '' > /etc/sysconfig/iptables
/etc/init.d/iptables restart


#generate packstack config
bash packstack.txt
cp packstack_now.txt  ~/packstack.txt

#install packstack
sudo yum install -y openstack-packstack

#install openstack allinone
packstack --answer-file=~/packstack.txt

#finished install

cd -
