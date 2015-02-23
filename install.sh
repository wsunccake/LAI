#!/bin/bash

#
### DATE:   2015/01/28
### AUTHOR: wsunccake 
#

usage() {
  echo "${0##*/} [server | testbed]"
  echo "${0##*/} and ${0##*/} server depoly PXE server"
  echo "${0##*/} testbed depoly testbed (only support KVM)"
}

#
# main
#

action=$1
bin_dir=${0%/install.sh}/bin

. $bin_dir/util.sh

if [ -z "$action" ] || [ x"$action" == x'server' ];
then
  echo "install and setup server"
  $bin_dir/build_server.sh `getPM`
elif [ x"$action" == x'testbed' ];
then
  echo "install testbed"
  $bin_dir/build_testbed.sh `getPM`
else
  usage
  exit 1
fi
