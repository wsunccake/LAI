#!/bin/bash

#
### modified date: 2015/01/29
### author: wsunccake
#

. ${0%/build_testbed.sh}/util.sh


installKvm() {
  pmu=$1
  if [ "x$pmu" == "xzypper" ]; then
    echo "zypper"
    runCommand "zypper install -y bridge-utils"
    runCommand "zypper install -y qemu kvm"
    runCommand "zypper install -y libvirt"
    runCommand "zypper install -y python-pip"
  elif [ "x$pmu" == "xyum" ]; then
    echo "yum"
  elif [ "x$pmu" == "xapt" ]; then
    echo "apt"
    runCommand "sudo apt-get update"
    runCommand "sudo apt-get install -y bridge-utils"
    runCommand "sudo apt-get install -y qemu-kvm"
    runCommand "sudo apt-get install -y libvirt-bin libvirt0"
    runCommand "sudo apt-get install -y python-pip"
  else
    echo "don't support"
  fi
}


installRobotframework() {

  pip install -U pip
  if [ "x$pipStatus" == "x0" ]; then
    pip install robotframework
    pip install robotframework-sshlibrary
  else
    wget --no-check-certificate https://pypi.python.org/packages/source/r/robotframework/robotframework-2.8.7.tar.gz#md5=42a38054fb24787e6d767e0a96315627
    pip install -i -f robotframework-2.8.7.tar.gz
    
    wget --no-check-certificate https://pypi.python.org/packages/source/p/pycrypto/pycrypto-2.6.tar.gz#md5=88dad0a270d1fe83a39e0467a66a22bb
    pip install -i -f pycrypto-2.6.tar.gz
    
    wget --no-check-certificate https://pypi.python.org/packages/source/e/ecdsa/ecdsa-0.11.tar.gz#md5=8ef586fe4dbb156697d756900cb41d7cpip install -i -f ecdsa-0.11.tar.gz
    
    wget --no-check-certificate https://pypi.python.org/packages/source/p/paramiko/paramiko-1.15.2.tar.gz#md5=6bbfb328fe816c3d3652ba6528cc8b4c
    pip install -i -f paramiko-1.15.2.tar.gz
    
    wget --no-check-certificate https://pypi.python.org/packages/source/r/robotframework-sshlibrary/robotframework-sshlibrary-2.1.tar.gz#md5=c086b396ef9dde9bcf9f3fa96ea92a81
    pip install -i -f robotframework-sshlibrary-2.1.tar.gz
  fi
}


# main
installKvm $1
installRobotframework
