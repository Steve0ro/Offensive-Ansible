#!/bin/sh

# Setup sudo token
sudo whoami

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
ansible-playbook main.yml -K
if [ $? -gt 0 ]; then
    printf "[!] Error occurred during playbook run.\n"
    exit 1    
fi

printf "[+] Install will take a bit.. Grab some coffee.\n If you are looking for more verbose output, add -vvv to line 27 of deploy.sh"
printf "[!] Finished\n"