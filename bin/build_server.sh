#!/bin/bash

#
### modified date: 2015/02/22
### author: wsunccake
#


. ${0%/build_server.sh}/util.sh


setDnsmasq() {
  # install dnsmasq package
  installPackage dnsmasq

  # configure dnsmasq file
  setPrompt tftp_dir "TFTP dir" /tftp
  backupFile $tftp_dir
  mkdir -p $tftp_dir

  setPrompt dnsmasqconf "dnsmasq configure file" /etc/dnsmasq.conf
  backupFile $dnsmasqconf
  touch $dnsmasqconf

  setPrompt dhcp_nic "DHCP interface" eth1
  echo "DHCP IP range"
  setPrompt dhcp_initial_ip "from" 192.168.1.50
  setPrompt dhcp_final_ip "to" 192.168.1.70
  setPrompt dhcp_netmask "DCHP netmask" 255.255.255.0
  setPrompt dhcp_release_time "DCHP release time"  12h
  setPrompt dhcp_broadcast "DHCP broadcast" 192.168.1.255
  setPrompt dhcp_default_gateway "DHCP default gateway:" 192.168.1.10
  setPrompt dhcp_dns "DHCP DNS" 192.168.1.10
  setPrompt tftp_ip "TFTP IP" 192.168.1.10

cat << EOF > $dnsmasqconf
# DHCP
bind-interfaces
interface=$dhcp_nic
#port=

dhcp-leasefile=/tmp/dnsmasq.leases
dhcp-range=${dhcp_initial_ip},${dhcp_final_ip},${dhcp_netmask},${dhcp_release_time} # ip range, [netmask], release time
#dhcp-host=aa:bb:cc:dd:ee:ff,192.168.1.100 # fixed ip

dhcp-option=1,${dhcp_netmask} #subnet mask
dhcp-option=28,${dhcp_broadcast} #broadcast
dhcp-option=3,${dhcp_default_gateway} #default gateway
dhcp-option=6,${dhcp_dns} #DNS

#  TFTP
dhcp-boot=pxelinux.0,$tftp_ip # tftp server ip
enable-tftp
tftp-root=$tftp_dir
EOF

  echo "create $dnsmasqconf"
  service restart dnsmasq
}


setPxe() {
  # install syslinux package
  installPackage syslinux

  # configure PXE
  if [ -z $tftp_dir ]; then
    setPrompt tftp_dir "TFTP dir" /tftp
    if [ ! -d $tftp_dir ]; then
      mkdir -p $tftp_dir
    fi
  fi

  cp /usr/share/syslinux/pxelinux.0 $tftp_dir
  cp /usr/share/syslinux/menu.c32 $tftp_dir

  mkdir -p $tftp_dir/pxelinux.cfg
  cat << EOF > $tftp_dir/pxelinux.cfg/default
ui              menu.c32
implicit        1
prompt          1
timeout         30
default         harddisk

# hard disk
label harddisk
  menu label Boot from local harddisk
  menu default
  localboot 0x80

EOF

  echo "set PXE image file [/root/distro.iso]"
  read pxe_image
  echo "which image file os distro [centos, fedora, opensuse, ubuntu]:"
  read target_os

  tmp_mnt=/tmp/`date +%Y%m%d%H%M%S`
  mkdir -p $tmp_mnt
  mount -oloop $pxe_image $tmp_mnt

  # copy vmlinux, initrd from iso image
  if [ x"$target_os" == "xcentos" ]; then
    mkdir -p $tftp_dir/$target_os
    cp -a $tmp_mnt/isolinux/{vmlinuz,initrd.img} $tftp_dir/$target_os
    cat << EOF >> $tftp_dir/pxelinux.cfg/default
label $target_os
  menu label Boot from centos
  kernel $target_os/vmlinuz 
  append initrd=$target_os/initrd.img method=http://$tftp_ip/iso/$target_os devfs=nomount inst.ks=http://$tftp_ip/iso/kickstart.cfg
#  append initrd=$target_os/initrd.img method=http://$tftp_ip/iso/$target_os devfs=nomount inst.ks=http://$tftp_ip/lai/kickstart.cfg inst.vnc inst.vncpassword=password

EOF
  else
    echo "don't support"
    exit 1
  fi
  umount $tmp_mnt

  echo "create $tftp_dir"
}


setHttp() {
  # install apache package
  installPackage httpd apache apache2

  # configure apache
  os=`getOS os`
  if [ "x$os" == "xcentos" ]; then
    lai_conf=/etc/httpd/conf.d/lai.conf
    iso_dir=/var/www/html/iso
  elif [ "x$os" == "xubuntu" ]; then
    lai_conf=/etc/httpd/conf.d/lai.conf
    iso_dir=/var/www/html/iso
  elif [ "x$os" == "xsles" ]; then
    lai_conf=/etc/apache2/conf.d/lai.conf
    iso_dir=/srv/www/htdocs/iso
  else
    echo "don't support"
    exit 1
  fi

  setPrompt lai_conf "http config" $lai_conf
  backupFile $lai_conf

  setPrompt iso_dir "iso dir" $iso_dir
  backupFile $iso_dir
  mkdir -p $iso_dir

  mkdir -p $tmp_mnt
  mount -oloop $pxe_image $tmp_mnt
  cp -r $tmp_mnt $iso_dir/$target_os
  umount $tmp_mnt

  cat << EOF > $lai_conf
Alias /iso "$iso_dir"

<Directory "$iso_dir">
    Options Indexes
    AllowOverride None
    Order Allow,Deny
    Allow from all
#    Order Deny,Allow
#    Deny from all
#    Allow from 192.168.1

</Directory>
EOF

  echo "create $lai_conf"
  service httpd restart
}


setAutoInstall() {
  # configure apache
  os=`getOS os`
  if [ "x$os" == "xcentos" ]; then
    lai_type=kickstart
  elif [ "x$os" == "xubuntu" ]; then
    lai_type=preseed
  elif [ "x$os" == "xsles" ]; then
    lai_type=autoyast
  else
    echo "don't support"
    exit 1
  fi

  if [ -z $iso_dir ]; then
    setPrompt iso_dir "iso dir" $iso_dir
    if [ ! -d $iso_dir ]; then
      mkdir -p $iso_dir
    fi
  fi

# openssl passwd -1 $rootpw
 cp ${0%/build_server.sh}/../etc/anaconda-ks.cfg $iso_dir/kickstart.cfg
 echo "create kickstart.cfg"

}


# main

setDnsmasq
setPxe
setHttp
setAutoInstall
