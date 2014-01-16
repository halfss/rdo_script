#!/bin/bash
# check user
if [ `whoami` != 'root' ];then
    echo "please use root to exec this script"
    exit 0
fi

cd `dirname $0`

. rdo.rc

#set ssh key
if [ ! -d ~/.ssh ];then
    mkdir ~/.ssh
fi
if [ ! -f ~/.ssh/id_rsa ];then
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi
cat ~/.ssh/authorized_keys | grep "`cat ~/.ssh/id_rsa.pub`"
if [ $? == 0 ];then
    echo "key already exists; pass"
else
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
fi

#clear iptables
echo '' > /etc/sysconfig/iptables
/etc/init.d/iptables restart

#add company mirrors
rpm -Uvh http://mirrors.halfss.com/halfss-mirrors-0.01-1.noarch.rpm

#generate packstack config
bash packstack.txt
cp packstack_now.txt  ~/packstack.txt

#install packstack
sudo yum install -y openstack-packstack

#install openstack allinone
packstack --answer-file=~/packstack.txt

#finished install

cd -
