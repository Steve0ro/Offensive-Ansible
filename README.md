# Parrot-Build

Original creator [IppSec's Parrot-Build](https://github.com/IppSec/parrot-build).

Modified by **Steve0ro**.

## Instructions

### Install Ansible
```bash
python3 -m pip install ansible
--or--
sudo apt install -y ansible
```

## Clone the repo.
```bash
git clone https://github.com/steve0ro/Offensive-Build
```

## Install requirements
```bash
ansible-galaxy install -r requirements.yml
```

## Make sure we have a sudo token 
```bash
sudo whoami
```

## Run full playbook
```bash
ansible-playbook main.yml
```

---

# To Do

- Add seperate playbooks for other nix* distros

---

### Currently works on kali and parrotOS