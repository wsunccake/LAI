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
  os=`lsb_release -a 2>&1 | awk '/Distributor ID:/{print $3}' | tr '[:upper:]' '[:lower:]'`
  if [ "x$os" == "xcentos" ]; then
    ver=`lsb_release -a | awk '/Release:/{print $2}'`
  elif [ "x$os" == "xubuntu" ]; then
    ver=`awk -F= '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release`
  elif [ "x$os" == x"suse" ]; then
    os=`lsb_release -a | grep "SUSE Linux Enterprise Server" &> /dev/null && echo "sles" || echo "opensuse"`
    ver=`awk '/VERSION/{print $3}' /etc/SuSE-release`
    ver="${ver}`awk '/PATCHLEVEL/{print "sp"$3}' /etc/SuSE-release`"
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
  elif [ "x$os" == x"sles" ] || [ "x$os" == x"opensuse" ]; then
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
    runCommand "sudo apt-get update"
    runCommand "sudo apt-get install -y $apt_pkg"
  elif [ "x$pmu" == "xzypper" ]; then
    runCommand "zypper install -y $zypper_pkg"
  else
    echo "don't support"
    exit 1
  fi
}
