# CM4 + Ubuntu Server Setup

GitHub Pages site with setup instructions for a Raspberry Pi **Compute Module 4**
(Lite, SD card) running **Ubuntu Server 22.04 LTS**, prepared for **ROS 2 Humble (ros-base)**.

Adapted from MSE 112 Lab 01 (Raspberry Pi 4 + Raspberry Pi OS Bullseye).

## Layout

```
index.md                 home page
Lab_01/index.md          the lab instructions
Lab_01/code/             helper scripts linked from the lab
  setup_network.sh         netplan: eth0 static/DHCP, Wi-Fi client/hotspot   (runs on the CM4)
  setup_swap.sh            zram + /swapfile                                    (runs on the CM4)
  check_system.sh          read-only ROS 2 readiness check                     (runs on the CM4)
  share_internet_*.sh/ps1  share laptop Wi-Fi to the CM4 over Ethernet         (runs on the laptop)
```

## Publishing

Settings → Pages → *Deploy from a branch* → `main` / `(root)`.
The theme (`pages-themes/hacker`) is loaded with `jekyll-remote-theme`, so no build workflow is needed.
