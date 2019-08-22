#!/bin/bash

# The MIT License (MIT)
#
# Copyright (C) 2019-present, Seingshin Lee <seingshinlee@gmail.com>
# All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the “Software”), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial
# portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Usage:
#     shell> sudo bash -c "$(wget -qO- TODO)"
# OS restrictions:
#     Only Ubuntu Linux 19.04, 18.04 LTS or 16.04 LTS can be supported!

ubuntu_version=$(lsb_release --release | cut -f 2)
ubuntu_version_prefix=$(echo ${ubuntu_version} | cut -c "1,2")
ubuntu_version_echo="> ${Okay} Your Ubuntu Linux version is ${ubuntu_version}, it's ok and continue... Done."
Jigsaw-Code_pre_url="https://raw.githubusercontent.com/Jigsaw-Code/outline-releases/master"

# Initialze ANSI colors
initializeANSI() {
    prefix="\033"
    red_foreground="${prefix}[31m"
    green_foreground="${prefix}[32m"
    yellow_foreground="${prefix}[33m"
    reset="${prefix}[0m"
}

initializeANSI

Okay="${green_foreground}[Okay]${reset}"
Error="${red_foreground}[Error]${reset}"
Notice="${yellow_foreground}[Notice]${reset}"

read_echo_okay=$(echo -e "${Okay}")
read_echo_notice=$(echo -e "${Notice}")
read_echo_error=$(echo -e "${Error}")

# Check if Docker CE is installed or not
check_docker_ce_is_installed() {
    if [ -f "/usr/bin/docker" ]; then
        echo -e "> ${Okay} Docker CE service is installed... Done."
    else
        echo -e "> ${Error} Docker CE service isn't installed... Done."
    fi
}

# Checkt Docker CE service status
check_docker_ce_service_status() {
    if [[ "$(systemctl status docker.service --no-pager | awk '/Active/ {print $2,$3}')" == "active (running)" ]]; then
        sudo systemctl status docker.service --no-pager
        echo "> ${Okay} Well! Docker CE service is enable... Done."
    else
        echo -e "> ${Notice} Sorry! Docker CE service is disable... Done. (+)"
        echo -e "> ${Okay} Continuing... Done."
        sudo systemctl enable docker.service
        echo -e "> ${Okay} Docker CE service has been set to boot from boot... Done."
        sudo systemctl start docker.service
        echo -e "> ${Okay} Docker CE service is starting... Done."
        sleep 2s
        check_docker_ce_service_status
    fi
}

# Add an official Docker CE apt-repository software source
add_docker_ce_apt_repository() {
    case "${ubuntu_version}" in
        19.04)
            sudo add-apt-repository \
            "deb [arch=${phy_arch}] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) \
            stable edge test"
            ;;
        18.10|18.04|16.04)
            sudo add-apt-repository \
            "deb [arch=${phy_arch}] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) \
            stable"
            ;;
        *)
            ;;
    esac

    apt-cache policy docker-ce

    if [[ $(apt-cache policy docker-ce | sed -n '3p' | awk -F "[~-]" '{print $4}') != "ubuntu" ]]; then
        echo -e "> ${Okay} Continuing... Done."
    else
        echo -e "> ${Notice} Re-add the official apt-repository software source of Docker CE... Done."
        sleep 0.5s
        add_docker_ce_apt_repository
    fi
    echo -e "> ${Okay} Add an apt-repository software source successfully... Done."

    sudo apt update -y
}

# Remove all Docker CE service
remove_all_docker_ce() {
    echo -e "> ${Okay} Docker CE service will be stopped immediately!"
    sudo systemctl stop docker.service
    echo -e "> ${Okay} Docker CE service has been stopped!"
    echo -e "> ${Okay} Continuing... Done."
    sleep 0.5s
    sudo apt-get purge docker* runc containerd.io -y
    sudo apt-get --purge autoremove docker* runc containerd.io -y
    sudo apt-get autoclean
    sudo groupdel docker

    sudo find / \( -path "/sys" -o -path "/proc" -o -path "/media" -o -path "/mnt" -o -path "/home" \) -prune \
    -o -name "*docker*" -print 2>/dev/null | \
    sudo xargs rm -rf

    if [ $(grep -c "https://download.docker.com/linux/ubuntu" /etc/apt/sources.list) ]; then
        sudo sed -i '$d' /etc/apt/sources.list
    fi

    sudo apt-key del $(sudo apt-key list | grep -B 1 "docker" | sed -n '1p' | sed s/[[:space:]]//g)
    sudo apt update -y
    echo -e "> ${Okay} Docker CE service has been removed completely!"
}

# Install Docker CE service
install_docker_ce() {
    # Add some dependencies and an official Docker GPG key
    echo -e "> ${Okay} Will add some dependencies and an official Docker GPG key... Done."
    sudo apt update -y
    sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    echo -e "> ${Okay} Will add Docker CE official apt-repository software source... Done."
    add_docker_ce_apt_repository

    if [ "$(apt-key list | grep -c "docker")" == 1 ]; then
        echo -e "> ${Okay} Add a GPG key successfully... Done."
    else
        echo -e "> ${Error} Failed to add a GPG key... Done. (+)"
        exit_information
    fi

    echo -e "> ${Okay} Will execute installation of Docker CE... Done."
    sudo apt install docker-ce -y
    check_docker_ce_service_status
}

# Update Docker CE service
update_docker_ce() {
    echo -e "> ${Okay} Will update Docker CE... Done."
    sudo apt update -y
    sudo apt install docker-ce -y
    echo -e "> ${Okay} Docker CE update successfully... Done."
}

# Check Linux operating system release
check_sys_release() {
    sys_release=$(cat /etc/os-release | awk '$1=="ID=ubuntu" {print $1}' | cut -b 4-9)
    if [ "${sys_release}" == "ubuntu" ]; then
        echo -e "> ${Okay} Your Linux release is Ubuntu ${ubuntu_version}. It's okay, Done."
    else
        echo -e "> ${Error} This script is only supported on Ubuntu Linux, please reinstall an Ubuntu Linux operating system and try again."
        exit_information
    fi
}

# Check CPU physical architecture
phy_arch=$(arch)
check_phy_arch() {
    if [[ "${phy_arch}" == "x86_64" ]]; then
        phy_arch=amd64
    elif [[ "${phy_arch}" == "arm64" ]]; then
        phy_arch=arm64
    else
        echo -e "> ${Notice} Physical architecture is not supported, please replace a new CPU architecture and try again."
        echo -e "> ${Notice} Only x86_64, arm64 and arm64 are supported!"
        echo -e "> ${Notice} Or you can go to the official website to find out more CPU architectures..."
        echo -e "> ${Notice} Click the right mouse button to open the link: https://docs.docker.com/install/linux/docker-ce/ubuntu"
        exit_information
    fi
    echo -e "> ${Okay} Your Ubuntu Linux Physical architecture is ${phy_arch}, it's ok and continuing... Done."
}

# Check number of Bit
bit=
check_bit() {
    if [ "$(getconf WORD_BIT)" == "32" ] && [ "$(getconf LONG_BIT)" == "64" ]; then
        bit=64
        echo -e "> ${Okay} Your operating system is ${bit}-Bit, continuing... Done."
    else
        bit=32
        echo ${bit}
        echo -e "> ${Error} Your operating system is not 64-Bit, please reinstall an Ubuntu Linux 64-Bit and try again."
        exit_information
    fi
}

# Check memory total of operating system
check_memory_total() {
    memory_total=$(($(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024))
    if [ "${memory_total}" -ge 512 ]; then
        echo -e "> ${Okay} Your machine memory is ${memory_total}MB, it's okay, continuing... Done."
    else
        echo -e "> ${Error} Machine memory is less than 512MB, please adjust to the memory size and try again."
        exit_information
    fi
}

# Check SSH server alive status
count_01=1
check_ssh_server_alive_status() {
    param=
    if [ "${count_01}" == 1 ]; then
        echo -e "> ${Notice} Check if SSH is enabled to keep the server alive interval time and the max response count or not?"
        echo -e "> ${Notice} if [y], your operating system upgrade will feedback progress information in real time."
        echo -e "> ${Notice} if [N], your operating system upgrade is very likely to fail!"
        read -p "< ${read_echo_notice} Do you continue? [y/N]: " param
    else
        read -p "< ${read_echo_notice} Do you continue again? [y/N]: " param
    fi

    case "${param}" in
        Y|y|[Yy][Ee][Ss])
            sshd_config_path="/etc/ssh/sshd_config"
            if [ ! -f "${sshd_config_path}" ]; then
                sudo apt-get --purge remove openssh-server -y
                sudo apt-get autoremove
                sudo apt-get clean
                sudo apt-get install openssh-server -y
            else
                sudo sed -i '/ClientAliveInterval/a\\ClientAliveInterval 60' ${sshd_config_path}
                sudo sed -i '/#ClientAliveInterval/d' ${sshd_config_path}
                sudo sed -i '/ClientAliveCountMax/a\\ClientAliveCountMax 3' ${sshd_config_path}
                sudo sed -i '/#ClientAliveCountMax/d' ${sshd_config_path}
            fi
            echo -e "> ${Okay} Modify the file \"/etc/ssh/sshd_config\" successfully!"
            ;;
        N|n|[Nn][Oo])
            echo -e "> ${Notice} Without modifing SSH server alive status... Done. (+)"
            ;;
        *)
            echo -e "> ${Error} Invalid input, please re-enter and try again... Done."
            count_01=$[${count_01}+1]
            check_docker_ce_service_status
            ;;
    esac
}

# Upgrade Ubuntu version
count_02=1
upgrade_ubuntu_version() {
    param=
    if [ "${count_02}" == 1 ]; then
        read -p "< ${read_echo_okay} This upgrade process will take a long time, are you sure to continue? [y/N]: " param
    else
        read -p "< ${read_echo_okay} Do you certainly upgrade to higher Ubuntu Linux version again? [y/N]: " param
    fi

    case "${param}" in
        Y|y|[Yy][Ee][Ss])
            echo -e "> ${Okay} Starting to execut upgrade commands... Done."
            echo -e "> ${Okay} Follow the prompts to perform the appropriate action!"
            sleep 2s
            sudo apt update -y
            sudo apt upgrade -y
            sudo apt dist-upgrade -y
            sudo apt-get autoremove -y
            sudo apt install update-manager-core -y
            if [ $(grep -c "Prompt=tls" /etc/update-manager/release-upgrades) ]; then
                sudo sed -i '$d' /etc/update-manager/release-upgrades
                sudo sed -i '$a\Prompt=normal' /etc/update-manager/release-upgrades
            fi
            sudo do-release-upgrade -d
            ;;
        N|n|[Nn][Oo])
            echo -e "> ${Okay} Stopped upgrade... Done."
            ;;
        *)
            echo -e "> ${Error} Invalid input, please re-enter and try again... Done."
            count_02=$[${count_02}+1]
            upgrade_ubuntu_version
            ;;
    esac
}

# Check Ubuntu version
count_03=1
check_ubuntu_version() {
    param=
    case "${ubuntu_version}" in
        19.04)
            echo -e ${ubuntu_version_echo}
            ;;
        18.10)
            echo -e ${ubuntu_version_echo}
            ;;
        18.04)
            echo -e ${ubuntu_version_echo}
            ;;
        16.04)
            echo -e ${ubuntu_version_echo}
            ;;
        *)
            if [ "${count_03}" == 1 ]; then
                echo -e "> ${Notice} Your Ubuntu Linux version is older, please reinstall the newer version like 19.04, 18.10, 18.04 LTS or 16.04 LTS and try again. (+)"
                read -p "< ${read_echo_notice} Or do you upgrade to higher Ubuntu Linux version now? Press enter [y/N]: " param
            else
                read -p "< ${read_echo_notice} Do you certainly upgrade to higher Ubuntu Linux version now? Press enter [y/N]: " param
            fi
            ;;
    esac

    case ${param} in
        Y|y|[Yy][Ee][Ss])
            check_ssh_server_alive_status
            upgrade_ubuntu_version
            ;;
        N|n|[Nn][Oo])
            exit_information
            ;;
        *)
            echo -e "> ${Error} Invalid input, please input a legal operation and continue... Done."
            count_03=$[${count_03}+1]
            check_ubuntu_version
            ;;
    esac
}

# Check if Outline Server is installed or not
check_outline_server_is_installed() {
    if [ -d "/opt/outline/persisted-state/outline-ss-server" ]; then
        echo -e "> ${Okay} Outline Server is installed... Done."
    else
        echo -e "> ${Error} Outline Server isn't installed... Done."
        exit_information
    fi
}

# Install or update Outline Server service of Ubuntu Server by Outline official One-click shell script
count_04=1
install_or_update_outline_server() {
    if [ "${count_04}" == 1 ]; then
        echo -e "> ${Okay} Will install Outline Server immediately... Done."
    else
        echo -e "> ${Okay} Will update Outline Server immediately... Done."
    fi

    sudo bash -c \
    "$(wget -qO- https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh)" -y \
    | tee $HOME/.install_or_update_outline_server.log

    cat $HOME/.install_or_update_outline_server.log | awk '/apiUrl/ {print $0}' | sudo tee /opt/outline/access_apiUrl.txt

    if [ "${count_04}" == 1 ]; then
        echo -e "> ${Okay} Install Outline Server successfully... Done."
    else
        echo -e "> ${Okay} Update Outline Server successfully... Done."
    fi
}

# Remove all Outline Server service
remove_all_outline_server() {
    echo -e "> ${Okay} Will remove all Outline Server service... Done."
    sudo kill $(ps -ef | grep "outline-ss-server" | awk '{print $2}')
    echo -e "> ${Okay} Has killed all Outline Server background processes... Done."
    docker_container_name=$(sudo docker ps | grep "outline" | awk '{print $NF}')
    sudo docker stop ${docker_container_name}
    echo -e "> ${Okay} Has stopped Outline Server docker container... Done."
    sudo docker rm ${docker_container_name}
    echo -e "> ${Okay} Has removed Outline Server docker container... Done."
    sudo docker rmi $(sudo docker image ls | grep "outline" | awk '{print $1":"$2}')
    echo -e "> ${Okay} Has removed Outline Server docker image... Done."
    sudo find / -path "/opt/outline" -prune \
    -o -name "outline-ss-server" \
    -print 2>/dev/null \
    | xargs rm -rf
    sudo rm -rf /opt/outline/{persisted-state/,access.txt*}
    sudo rm $HOME/.install_or_update_outline_server.log
    echo -e "> ${Okay} Good! Remove all Outline Server service successfully."
}

# Check if Outline Manager Client and Outline Client are installed or not
check_outline_clients_are_installed() {
    if [ -d "/opt/outline/outline-manager-client" ] && [ -d "/opt/outline/outline-client" ]; then
        echo -e "> ${Okay} Both of them are installed... Done."
    elif [ -d "/opt/outline/outline-manager-client" ]; then
        echo -e "> ${Okay} Only Outline Manager Client is installed... Done."
    elif [ -d "/opt/outline/outline-client" ]; then
        echo -e "> ${Okay} Only Outline Client is installed... Done."
    else
        echo -e "> ${Notice} Neither!"
    fi
}

# Check Outline Manager Client and Outline Client status
check_outline_clients_are_enabled() {
    if [ $(ps -e | grep -c "outline-manager") == 4 ] && [ $(ps -e | grep -c "outline-client") == 4 ]; then
        echo -e "> ${Okay} Both of them are enabled... Done."
    elif [ $(ps -e | grep -c "outline-manager") == 4 ]; then
        echo -e "> ${Okay} Only Outline Manager Client is enabled... Done."
    elif [ $(ps -e | grep -c "outline-client") == 4 ]; then
        echo -e "> ${Okay} Only Outline Client is enabled... Done."
    else
        echo -e "> ${Notice} Neither!"
    fi
}

# Install Outline Manager Client
install_outline_manager_client() {
    cur_dir=$(pwd)
    if [ ! -f "Outline-Manager.AppImage" ]; then
        sudo wget ${Jigsaw-Code_pre_url}/manager/stable/Outline-Manager.AppImage
    else
        sudo wget -N -c ${Jigsaw-Code_pre_url}/manager/stable/Outline-Manager.AppImage
    fi

    sudo chmod a+x Outline-Manager.AppImage
    mkdir -p outline/outline-manager-client
    sudo mv Outline-Manager.AppImage ${cur_dir}/outline-manager-client

    seingshinlee_pre_url="https://raw.githubusercontent.com/seingshinlee/outline-vpn-mirrors/master/statics"
    if [ ! -f "outline-manager-client.png" ]; then
        sudo wget ${seingshinlee_pre_url}/outline-manager-client.png
    fi

    sudo mv outline-manager-client.png ${cur_dir}/outline-manager-client

    cat >${cur_dir}/outline-manager-client/outline-manager-client.desktop <<-EOF
[Desktop Entry]
Encoding=UTF-8
Name=Outline Manager
GenericName=Outline VPN - Outline Manager Client
Comment=The Outline Manager application creates and manages Outline servers, powered by Shadowsocks.
Exec=/opt/outline/outline-manager-client/Outline-Manager.AppImage %f
Icon=/opt/outline/outline-manager-client/outline-manager-client.png
Terminal=false
Type=Application
Categories=Internet
StartupNotify=true
EOF

    sudo rsync -a ${cur_dir}/ /opt/outline
    sudo ln -sfn /opt/outline/outline-manager-client/outline-manager-client.desktop /usr/share/applications/outline-manager-client.desktop
    sudo ln -sfn /opt/outline/outline-manager-client/outline-manager-client.desktop $HOME/.config/autostart/outline-manager-client.desktop
    echo -e "> ${Okay} Install Outline Manager Client successfully!"
}

# Install Outline Client
install_outline_client() {
    cur_dir=$(pwd)
    if [ ! -f "Outline-Client.AppImage" ]; then
        sudo wget ${Jigsaw-Code_pre_url}/client/stable/Outline-Client.AppImage
    else
        sudo wget -N -c ${Jigsaw-Code_pre_url}/client/stable/Outline-Client.AppImage
    fi

    sudo chmod a+x Outline-Client.AppImage
    mkdir -p outline/outline-client
    sudo mv Outline-Client.AppImage ${cur_dir}/outline-client

    seingshinlee_pre_url="https://raw.githubusercontent.com/seingshinlee/outline-vpn-mirrors/master/statics"

    if [ ! -f "outline-client.png" ]; then
        sudo wget ${seingshinlee_pre_url}/outline-client.png
    fi

    sudo mv outline-client.png ${cur_dir}/outline-client

    cat >${cur_dir}/outline-client/outline-client.desktop <<-EOF
[Desktop Entry]
Encoding=UTF-8
Name=Outline
GenericName=Outline VPN - Outline Client
Comment=The Outline Client is a cross-platform VPN or proxy client for Windows, macOS, iOS, Android, and Chrome OS.
Exec=/opt/outline/outline-client/Outline-Client.AppImage %f
Icon=/opt/outline/outline-client/outline-client.png
Terminal=false
Type=Application
Categories=Internet
StartupNotify=true
EOF

    sudo rsync -a ${cur_dir}/ /opt/outline
    sudo ln -sfn /opt/outline/outline-client/outline-client.desktop /usr/share/applications/outline-client.desktop
    sudo ln -sfn /opt/outline/outline-client/outline-client.desktop $HOME/.config/autostart/outline-client.desktop
    echo -e "> ${Okay} Install Outline Client successfully!"
}

# Update Outline Manager Client
update_outline_manager_client() {
    sudo kill $(ps -ef | grep "outline-manger" | awk '{print $2}')
    if [ ! -f "Outline-Manager.AppImage" ]; then
        sudo wget ${Jigsaw-Code_pre_url}/manager/stable/Outline-Manager.AppImage
    else
        sudo wget -N -c ${Jigsaw-Code_pre_url}/manager/stable/Outline-Manager.AppImage
    fi

    sudo chmod a+x Outline-Manager.AppImage
    sudo rsync -a Outline-Manager.AppImage /opt/outline/outline-manager-client/outline-manager-client
    echo -e "> ${Okay} Update Outline Manager Client successfully!"
}

# Update Outline Client

# Remove Outline Manager Client

# Remove Outline Client

# Topic information

# Common options for Ubuntu Linux Desktop and Server

# Options only support Ubuntu Desktop

# Options only support Ubuntu Server

# If continue to use start_menu function or not

# Check all prerequisites

# One option for the 7th option in main case...in process control statement

# One option for the 11th or the 12th option in main case...in process control statement

# One option for the 26th option in main case...in process control statement

# One option for the 27th option in main case...in process control statement

# One option for the common of the 26th and the 27th options in main case...in process control statement

# Exit Information to all

# Start entrance menu
