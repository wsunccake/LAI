*** Settings ***
Library     OperatingSystem
Library     SSHLibrary  WITH NAME  SSH


*** Variables ***
#${HOST}  127.0.0.1
#${USERNAME}  test
#${PASSWORD}  test


*** Keywords ***
SSH Login
    [Arguments]    ${host}=${HOST}  ${username}=${USERNAME}  ${password}=${PASSWORD}
    Open Connection  ${host}
    Login  ${username}  ${password}


SSH Login As Root
    [Arguments]    ${host}=${HOST}  ${password}=${PASSWORD}
    Open Connection  ${host}
    Login  root  ${password}


Run Command
    [Arguments]    ${cmd}  ${timeout}=1s
    Write  ${cmd}
    ${stdout}=  Read  delay=${timeout}


Run Commands
    [Arguments]    @{cmds}
    :FOR  ${cmd}  IN  @{cmds}
    \     Run Command  ${cmd}

Run Command With Regexp
    [Arguments]    ${cmd}  ${timeout}=1s  ${pattern}
    Write  ${cmd}
    ${stdout}=  Read  delay=${timeout}
    Should Match Regexp  ${stdout}  ${pattern}
