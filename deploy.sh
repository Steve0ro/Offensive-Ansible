#!/bin/sh

# Setup sudo token
sudo whoami

# Ensure .local/bin is in the PATH for ansible executables
export PATH=$PATH:$HOME/.local/bin
export PATH=/home/$USER/.nimble/bin:$PATH

if ! command -v ansible >/dev/null; then
    printf "[+] Installing Ansible\n"
    sudo apt-get update -y && sudo apt-get install -y ansible
    if [ $? -gt 0 ]; then
        printf "[!] Error occurred when attempting to install ansible package.\n"
        exit 1
    fi
fi

printf "[+] Downloading required Ansible collections\n"
ansible-galaxy install -r requirements.yml
if [ $? -gt 0 ]; then
    printf "[!] Error occurred when attempting to install Ansible collections.\n"
    exit 1
fi

printf "[+] Running playbooks in verbose mode..\n"
ansible-playbook main.yml -vvv -K
if [ $? -gt 0 ]; then
    printf "[!] Error occurred during playbook run.\n"
    exit 1    
fi

printf "[!] Finished\n"
