# Network Interface and USB Hub Reset Service

This repository provides a script and systemd service for monitoring and resetting a network interface and USB hub on a Linux system. The script checks the status of the specified network interface and resets the USB hub if the interface is down.

## Overview

The `reset-network.sh` script performs the following tasks:
- Checks if the specified network interface is up.
- If the interface is down, attempts to bring it up.
- If the interface remains down, resets the USB hub associated with it.
- The service ensures the script runs on boot and restarts automatically if it fails.

## Script and Service Setup

### 1. Retrieve the Script and Service

You can retrieve and set up the script and systemd service using `curl` from your private GitHub repository:

```bash
curl -L -o /usr/local/bin/reset-network.sh https://raw.githubusercontent.com/vinn-chege/usbhub-network-reset/main/setup_reset_network.sh
```

```bash
chmod +x /usr/local/bin/reset-network.sh
sudo ./usr/local/bin/reset-network.sh
```
