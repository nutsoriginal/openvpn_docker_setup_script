#!/bin/sh

# Install docker, docker-compose
# Run OpenVPN in docker-compose
# Init OpenVPN
# Generate one certificate for client by your host and username

echo "This script is going to:"
echo "- Install docker, docker-compose"
echo "- Run OpenVPN in docker-compose"
echo "- Init OpenVPN"
echo "- Generate one certificate for client by your host and username"
echo

while read -p "Continue? [y/n] " CONTINUE
do
    case "$CONTINUE" in
        y|Y ) break ;;
        n|N ) echo "Bye" && exit ;;
        * )   ;;
    esac
done
echo

DISTRO_NAME=$(echo "$(lsb_release -is)" | awk '{print tolower($0)}')
case "$DISTRO_NAME" in
    ubuntu ) ;;
    debian ) ;;
    * ) echo "Sorry, your distro is not ubuntu/debian" && exit ;;
esac


if ! [[ $(ps -p $$) =~ "bash" ]]
then
    echo "Please run this script in bash"
    echo
    exit 1
fi

if ! command -v apt-get &> /dev/null
then
    echo "apt-get could not be found"
    echo
    exit 1
fi

apt-get update

if command -v docker &> /dev/null
then
    while read -p "Docker installation found! Do you wish to reinstall docker and container env? [y/n] " CONTINUE
    do
        case "$CONTINUE" in
            y|Y ) apt-get remove docker docker-engine docker.io containerd runc
                  apt-get install ca-certificates curl gnupg lsb-release
                  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DISTRO_NAME $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                  apt-get update
                  apt-get install docker-ce docker-ce-cli containerd.io
                  break
                  ;;
            n|N ) echo "Continuing with your docker installation!" && break ;;
            * )   ;;
        esac
    done
    echo
else
    apt-get install ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DISTRO_NAME $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install docker-ce docker-ce-cli containerd.io
fi

if command -v docker-compose &> /dev/null
then
    while read -p "Docker-compose installation found! Do you wish to reinstall it? [y/n] " CONTINUE
    do
        case "$CONTINUE" in
            y|Y ) rm -f "$(which docker-compose)"
                  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                  chmod +x /usr/local/bin/docker-compose
                  break
                  ;;
            n|N ) echo "Continuing with your docker-compose installation!" && break ;;
            * )   ;;
        esac
    done
    echo
else
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

mkdir -p /opt/openvpn
mkdir -p /opt/openvpn/ovpn-data
touch /opt/openvpn/docker-compose.yml
DC_CONFIG=$'version: \"3\"\nservices:\n  ovpn:\n    image: kylemanna/openvpn:2.4\n    restart: always\n    volumes:\n      - ./ovpn-data:/etc/openvpn:rw\n    ports:\n      - 1194:1194/udp\n    cap_add:\n      - NET_ADMIN'
echo "$DC_CONFIG" >> /opt/openvpn/docker-compose.yml

docker-compose -f /opt/openvpn/docker-compose.yml up -d

while read -p "Your server hostname or IP: " HOST
echo
do
    if [[ -n $HOST ]]
    then
        break
    fi
done

docker-compose -f /opt/openvpn/docker-compose.yml run --rm ovpn ovpn_genconfig -u udp://$HOST
docker-compose -f /opt/openvpn/docker-compose.yml run --rm ovpn ovpn_initpki

while read -p "Your username: " USERNAME
echo
do
    if [[ -n $USERNAME ]]
    then
        break
    fi
done

docker-compose -f /opt/openvpn/docker-compose.yml run --rm ovpn easyrsa build-client-full $USERNAME nopass
docker-compose -f /opt/openvpn/docker-compose.yml run --rm ovpn ovpn_getclient $USERNAME > /opt/openvpn/$USERNAME.ovpn
