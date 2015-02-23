*** Settings ***
Resource  resource/common.robot


*** Variables ***


*** Keywords ***
Set VM xml
    @{cmds}=  Create List  cp -f LAI/src/test/vm.xml /tmp
                      ...  sed -i s@VBRIDGE@${VBRIDGE}@ /tmp/vm.xml
                      ...  sed -i s@VM_DISK@${VM_DISK}@ /tmp/vm.xml
                      ...  sed -i s@VM_NAME@${VM_NAME}@ /tmp/vm.xml
                      ...  sed -i s@VM_MAC@${VM_MAC}@ /tmp/vm.xml
                      ...  sed -i s@QEMU_KVM@${QEMU_KVM}@ /tmp/vm.xml
    Run Commands  @{cmds}


*** Test Cases ***
Show Hostname
    SSH Login
    Write  hostname
    ${stdout}=  Read
    Log  ${stdout}
    Close Connection


Install LAI In Server
    SSH Login As Root  ${SERVER_IP}  ${SERVER_PW}
    Start Command  which git
    ${stdout}  ${stderr}=  Read Command Output  return_stderr=True
    Should Be Empty  ${stderr}

    Run Command  test -d LAI && rm -rf LAI
    Run Command  git clone ${LAI_GITHUB}  20s
    # Run Command  ./LAI/install.sh  4s
    Run Command With Regexp  ./LAI/install.sh  4s  TFTP dir
    Run Command With Regexp  /tftp  2s  dnsmasq configure file
    Run Command With Regexp  /etc/dnsmasq.conf 2s  DHCP interface
    Run Command With Regexp  eth1  2s  from
    Run Command With Regexp  192.168.1.10  2s  to
    Run Command With Regexp  192.168.1.20  2s  DCHP netmask
    Run Command With Regexp  255.255.255.0 2s  DCHP release time
    Run Command With Regexp  12h  2s  DHCP broadcast
    Run Command With Regexp  192.168.1.255  2s  DHCP default gateway:
    Run Command With Regexp  192.168.1.10  2s  dhcp_dns DHCP DNS
    Run Command With Regexp  192.168.1.10  2s  tftp_ip TFTP IP
    Run Command With Regexp  192.168.1.10  2s



Create Guest VM
    SSH Login As Root  ${TESTBED_IP}  ${TESTBED_PW}
    Run Commands  qemu-img create -f qcow2 ${VM_DISK} 10G  5s
    Set VM xml

    Write  virsh define /tmp/vm.xml
    ${stdout}=  Read  delay=2s
    ${ret}=  Should Match Regexp  ${stdout}  Domain ${VM_NAME} defined from /tmp/vm.xml

    Run Command  virsh list --all  2s
    Run Command  virsh start ${VM_NAME}  2s


Delete Guest VM
    SSH Login As Root  ${TESTBED_IP}  ${TESTBED_PW}
    Run Command  virsh undefine --managed-save ${VM_NAME}  2s
    Run Command  virsh list --all  2s
