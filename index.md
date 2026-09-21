---
layout: default
title: Home
---

# CM4 + Ubuntu Server Setup
## Compute Module 4 · Ubuntu Server 22.04 LTS · ROS 2 Humble ready

```
> Board:   Raspberry Pi Compute Module 4 Lite (SD card) on the official CM4 IO Board
> OS:      Ubuntu Server 22.04 LTS (64-bit, arm64), headless
> Goal:    a networked, updated CM4 ready for ros-humble-ros-base
```

---

## Labs

| Lab | Topic |
|-----|-------|
| [Lab 01 — CM4 Setup & SSH](Lab_01/) | Flash Ubuntu Server 22.04 to the SD card, connect over SSH, set up networking and swap, test the GPIO header with an LED and a button, and prepare for ROS 2 |

<!--
Planned:
| Lab 02 — ROS 2 Humble Base | Install ros-humble-ros-base, colcon, and a first workspace |
-->

---

## Why these versions?

**ROS 2 Humble Hawksbill** is an LTS release (supported until May 2027) whose Tier 1
platform is **Ubuntu 22.04 "Jammy"** on **arm64**. Installing Ubuntu 22.04 on the CM4
means ROS 2 installs as ready-built `apt` packages. You do not have to compile ROS 2
from source.
