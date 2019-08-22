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

# Upgrade Ubuntu version

# Check Ubuntu version

# Check if Outline Server is installed or not

# Install or update Outline Server service of Ubuntu Server by Outline official One-click shell script

# Remove all Outline Server service

# Check if Outline Manager Client and Outline Client are installed or not

# Check Outline Manager Client and Outline Client status

# Install Outline Manager Client

# Install Outline Client

# Update Outline Manager Client

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
