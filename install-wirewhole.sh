#!/usr/bin/env bash

# Colors
RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
GREY='\033[1;30m'
NC='\033[0m' # No Color
# End Colors

function print_red()
{
    printf "${RED}${1}${NC}"
}

function print_blue()
{
    printf "${BLUE}${1}${NC}"
}

function print_green()
{
    printf "${GREEN}${1}${NC}"
}

function print_grey()
{
    printf "${GREY}${1}${NC}"
}

function print_error()
{
    print_red "[Error]"
    printf " $*\n"
}

function print_info()
{
    print_blue "[Info]"
    printf " $*\n"
}

function print_success()
{
    print_green "[Success]"
    printf " $*\n"
}

function print_debug()
{
    print_grey "[debug]"
    printf " $*\n"
}

function ask_yes_no ()
{
    read -p "$1 " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
    fi
}

function check_is_root ()
{
    if [ "$EUID" -ne 0 ]
    then 
        print_error "Please run script as root"
        exit
    fi
}

function run_as ()
{
    su - $1 -c "$2"
}

print_green "### Wirehole intall script\n"
print_green "### .......\n"

echo
print_blue "This script will install wirehole (https://github.com/Doka-NT/wirehole-squid.git) on your server\n"
echo ""



print_info "Disabling ping for this server"
set -x
sudo sysctl -w net.ipv4.icmp_echo_ignore_all=1
sudo bash -c 'echo "net.ipv4.icmp_echo_ignore_all=1" >> /etc/sysctl.conf'
set +x

print_info "Update rmem_max"
set -x
sudo sysctl -w net.core.rmem_max=1048576 
sudo bash -c 'echo "net.core.rmem_max=1048576" >> /etc/sysctl.conf'
set +x

print_info "Enable ip forwarding"
set -x
sudo sysctl -w net.ipv4.ip_forward=1
sudo bash -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'
set +x

print_info "Creating new user with sudo privileges"
read -rep $'Enter new OS username to create:\n' os_user

sudo adduser $os_user
sudo usermod -aG sudo $os_user

print_info "Installing docker"
sudo apt update && sudo apt install -y docker.io make

print_info "Installing docker-compose"
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

print_info "Update user permissions for docker"
sudo gpasswd -a $os_user docker

os_user_home="/home/$os_user"

sudo rm -rf $os_user_home/wirewhole

print_info "Try to delete existing containers if exists"
sudo docker rm -fv wireguard pihole unbound

print_info "Cloning wirewhole"
sudo -iu $os_user bash <<XXX
git clone https://github.com/Doka-NT/wirehole-squid.git $os_user_home/wirewhole
sleep 1
cd $os_user_home/wirewhole

sed -i "s/PEERS=1/PEERS=4/g" docker-compose.yml

mkdir -p $os_user_home/wirewhole/unbound
touch $os_user_home/wirewhole/unbound/unbound.log
chmod -R 0777 $os_user_home/wirewhole

make up

echo "Waiting for wirewhole is running"
sleep 10
docker-compose logs wireguard
XXX

for i in {1..4}; do echo; print_success "Configuration for Peer $i"; cat "$os_user_home/wirewhole/wireguard/peer$i/peer$i.conf"; done
