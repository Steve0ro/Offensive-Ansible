# Offensive-Ansible Build
A streamlined Linux build deployment tool originally created by IppSec, and thoughtfully modified and maintained by Steve0ro to support modern offensive security workflows.

## Overview
Automates the setup of a penetration testing environment on Kali-Linux distribution. It provides a simplified deployment mechanism via a single script, ideal for offensive security professionals and enthusiasts looking to quickly bootstrap their toolkit.

## Getting Started
1. Clone the Repository

```bash
git clone https://github.com/steve0ro/Offensive-Build
cd Offensive-Build
```

2. Run the Deployment Script in `Verbose` mode
```bash
bash ./deploy.sh -v
```

3. Run the Deployment Script in `Normal` mode
```bash
bash ./deploy.sh -y
```

4. Run the Deployment Script in `Quiet` mode
```bash
bash ./deploy.sh -q
```

5. Run the Deployment Script for `Help Menu` 
```bash
bash ./deploy.sh -h
```

This will install the necessary tools and configurations specific to your environment.

### Compatibility
✅ Kali Linux

### ⚠️ Support for additional Linux distributions is under development.

### Roadmap
- Create dedicated Ansible playbooks for additional Unix-like distributions (e.g., Ubuntu, Arch, Fedora)

- Improve logging and error handling

- Add user-selectable modules during setup

#### Acknowledgements
Original concept and build: IppSec

Customization and enhancements: Steve0ro

License
This project is licensed under the MIT License. See the LICENSE file for details.