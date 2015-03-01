#!/bin/bash

#
### DATE:   2015/02/22
### AUTHOR: wsunccake 
#


runCommand() {
  cmd="$1"
  falseStop=${2:true}
  echo $cmd
  $cmd
  cmdReturn=$?
  if [ "$cmdReturn" != "0" ] && [ "$falseStop" == "true" ]; then
    exit 1
  fi
}


wrapCommand() {
  cmd="$1"
  echo $cmd
  $cmd 2>&1 && echo "true" || echo "false"
}


backupFile() {
  backup_date=`date +%Y%m%d%H%M%S`
  backup_file=$1
  if [ -d "$backup_file" ] || [ -f "$backup_file" ]; then
    mv $backup_file ${backup_file}_${backup_date}
  fi
}


setPrompt() {
  defaultValue=$1
  echo -n "$2 [$3]:"
  read tmpValue
  eval $defaultValue=${tmpValue:-$3}
}


getOS() {
  os=unknown
  ver=unknown
  
  release_file=/etc/os-release
  if [ -f $release_file ]; then
    # CentOS Linux release 7.0.1406 (Core)
    # Ubuntu
    os=`awk -F= '/^ID=/{print $2}' $release_file | tr -d \"`
    ver=`awk -F= '/^VERSION_ID=/{print $2}' $release_file | tr -d \"`
  else
    release_file=`find -H /etc -maxdepth 1 -name "*-release" -exec readlink -f {} \; | sort -u | grep -vE '/etc/lsb-release|/etc/os-release'`
    os=`head -1 $release_file | awk '{print $1}' | tr '[:upper:]' '[:lower:]'`
  fi

  if [ "x$ver" == "xunknown" ]; then
    # SUSE Linux Enterprise Server 11 (x86_64)
    # openSUSE 13.2 (x86_64)
    ver=`awk '/VERSION/{print $3}' $release_file`
    ver="${ver}`awk '/PATCHLEVEL/{print "sp"$3}' release_file`"
  fi

  if [ "x$1" == "xos" ]; then
    echo ${os}
  elif [ "x$1" == "xver" ]; then
    echo "${ver}"
  else
    echo "${os}_${ver}"
  fi
}


getPM() {
  pm=unknown
  pmu=unknown
  os=`getOS os`
  ver=`getOS ver`
  if [ "x$os" == "xcentos" ]; then
    pm=rpm
    pmu=yum
  elif [ "x$os" == "xubuntu" ]; then
    pm=dpkg
    pmu=apt
  elif [ "x$os" == x"suse" ] || [ "x$os" == x"opensuse" ]; then
    pm=rpm
    pmu=zypper
  fi

  if [ "x$1" == "xpm" ]; then
    echo "${pm}"
  elif [ "x$1" == "xpmu" ]; then
    echo "${pmu}"
  else
    echo "${pm}_${pmu}"
  fi
}


installPackage() {
  if [ "$#" == "1" ]; then
    yum_pkg=$1
    apt_pkg=$yum_pkg
    zypper_pkg=$yum_pkg
  elif [ "$#" == "3" ]; then
    yum_pkg=$1
    apt_pkg=$2
    zypper_pkg=$3
  else
    echo "installPkacge yum_pkg apt_pkg zypper_pkg"
    exit 1
  fi

  pmu=`getPM pmu`
  if [ "x$pmu" == "xyum" ]; then
    runCommand "yum install -y $yum_pkg"
  elif [ "x$pmu" == "xapt" ]; then
    # runCommand "sudo apt-get update"
    runCommand "sudo apt-get install -y $apt_pkg"
  elif [ "x$pmu" == "xzypper" ]; then
    runCommand "zypper install -y $zypper_pkg"
  else
    echo "don't support"
    exit 1
  fi
}
