# Quick OpenVPN setup script

1. Copy script to your debian/ubuntu server
2. Run openvpn_docker_setup.sh with sudo
3. Follow instructions
    - Agree packages installation
    - Enter and save your new CA Key passphrase (several times)
    - Enter your server IP or hostname
    - Enter your new client_name
4. Download generated /opt/openvpn/<client_name>.ovpn file
5. Setup OpenVPN Connect client with your <client_name>.ovpn file
6. Enjoy
