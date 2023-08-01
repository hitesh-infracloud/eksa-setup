#!/bin/bash
# install-pre-prequisites.sh

exit_out() {
    echo ${1} && echo && exit -1
}

check-ubuntu-os-version(){
    version=$(cat /etc/issue | awk '{print $2}')
    echo -e "[+] Checking ubuntu os version"
    if [ $(printf '%s\n' "20.04" "$version" | sort -V | tail -n 1) = "$version" ]; then 
        echo "OK"
    else 
        exit_out "Only supported on Ubuntu 20.04 or higher. Exiting!!!" 
    fi
}

flush-iptables() {
    echo -e "[+] Flushing local iptables"
    iptables -F; iptables -t nat -F; netfilter-persistent save
}

## following steps as mentioned in https://serverspace.io/support/help/install-tightvnc-server-on-ubuntu-20-04/
## vnc server is required to host server so that clients are able to connect to the host VM.

install-vnc() {
    echo -e "[+] Installing vnc"
    apt-get update 
    DEBIAN_FRONTEND=noninteractive apt-get -y install xfce4 xfce4-goodies
    apt install -y tightvncserver
    mkdir -p /root/.vnc
    echo "eksapass" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd
    echo "IyEvYmluL2Jhc2gKeHJkYiAvcm9vdC8uWHJlc291cmNlcwpzdGFydHhmY2U0ICYK" | base64 -d > /root/.vnc/xstartup 
    chmod +x /root/.vnc/xstartup
    echo "W1VuaXRdCkRlc2NyaXB0aW9uPVN0YXJ0IFRpZ2h0Vk5DIHNlcnZlciBhdCBzdGFydHVwCkFmdGVyPXN5c2xvZy50YXJnZXQgbmV0d29yay50YXJnZXQKCltTZXJ2aWNlXQpUeXBlPWZvcmtpbmcKVXNlcj1yb290Ckdyb3VwPXJvb3QKV29ya2luZ0RpcmVjdG9yeT0vcm9vdAoKUElERmlsZT0vcm9vdC8udm5jLyVIOiVpLnBpZApFeGVjU3RhcnRQcmU9LS91c3IvYmluL3ZuY3NlcnZlciAta2lsbCA6JWkgPiAvZGV2L251bGwgMj4mMQpFeGVjU3RhcnQ9L3Vzci9iaW4vdm5jc2VydmVyIC1kZXB0aCAyNCAtZ2VvbWV0cnkgMTY4MHgxMDUwIC1sb2NhbGhvc3QgOiVpCkV4ZWNTdG9wPS91c3IvYmluL3ZuY3NlcnZlciAta2lsbCA6JWkKCltJbnN0YWxsXQpXYW50ZWRCeT1tdWx0aS11c2VyLnRhcmdldAo=" | base64 -d > /etc/systemd/system/vncserver@.service
    systemctl daemon-reload
    systemctl enable vncserver@1.service
    systemctl start vncserver@1
}

install-vbox-vagrant() {
    echo -e "[+] Installing Virtualbox"
    apt-get update
    wget https://download.virtualbox.org/virtualbox/7.0.6/virtualbox-7.0_7.0.6-155176~Ubuntu~focal_amd64.deb
    apt-get install -y ./virtualbox-7.0_7.0.6-155176~Ubuntu~focal_amd64.deb
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    apt-get update
    apt-get install -y vagrant 
    vagrant plugin install vagrant-disksize
    vagrant plugin install vagrant-persistent-storage
}


check-ubuntu-os-version
flush-iptables
install-vnc
install-vbox-vagrant