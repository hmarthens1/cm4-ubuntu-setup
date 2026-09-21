---
layout: default
title: "Lab 01 — CM4 Setup & SSH"
---

# Lab 01 — CM4 Setup & SSH

**Compute Module 4 · Official CM4 IO Board · Ubuntu Server 22.04 LTS**

**Objectives:** Flash Ubuntu Server 22.04 LTS (64-bit) to an SD card and boot the CM4 on the IO board without a monitor. Then connect over SSH, set up networking (static Ethernet IP and an optional Wi-Fi hotspot), update the system and add swap. Check the GPIO header by wiring an LED and a push-button, and finish by preparing the CM4 for **ROS 2 Humble (ros-base)**.

---

## Before You Start

You will need:
- A laptop (Windows, macOS or Linux)
- A **Raspberry Pi Compute Module 4 Lite** (the model without eMMC, which boots from an SD card), preferably a wireless model
- The **official Raspberry Pi CM4 IO Board**
- The **12 V DC power supply** for the IO board (barrel jack)
- A micro-SD card (16 GB or more, class A1 or faster) and a card reader
- An Ethernet cable
- For Part 8: a breadboard, one LED, one 330 Ω resistor, one push-button and 4 female-to-male jumper wires

Optional: an HDMI monitor and USB keyboard, for setting the hostname at the console (Part 2.1) or for troubleshooting.

### Know your CM4

The part number printed on the module tells you what you have: `CM4` **W** **RR** **SSS**.

| Part | Meaning | What it changes in this lab |
|---|---|---|
| **W** = 1 | Has Wi-Fi/Bluetooth | `W` = 0 → no Wi-Fi: skip the Wi-Fi and hotspot steps, use Ethernet only |
| **RR** | RAM in GB (01, 02, 04, 08) | 1–2 GB → swap (Part 7) matters a lot for building ROS 2 packages |
| **SSS** = 000 | **Lite** — no eMMC, boots from SD | This lab assumes Lite |

> **eMMC models ignore the SD card slot.** If your part number does *not* end in `000`,
> the CM4 has on-board eMMC and needs `rpiboot` to flash. This lab does not cover that.

### Prepare the IO board

1. Seat the CM4 on the IO board: line up both connectors and press down evenly until they click.
2. Make sure the **J2 jumper ("Fit jumper to disable eMMC Boot") is NOT fitted**. With it
   fitted, the CM4 waits for a USB host (rpiboot) and never boots from the SD card.
3. Power the board **only** from the 12 V barrel jack. The micro-USB port on the IO board is a
   USB *device* port for flashing. It does not power the board.
4. Leave the power off until Part 2.

> **Why Ubuntu 22.04 and not the newest Ubuntu?** ROS 2 Humble is released as ready-built
> packages for Ubuntu 22.04 "Jammy" only. On a newer Ubuntu you would have to compile
> ROS 2 from source.

---

## Part 1 — Flash Ubuntu Server to the SD card

### 1.1 Install Raspberry Pi Imager

Download and install **[Raspberry Pi Imager](https://www.raspberrypi.com/software/)** on your laptop.
Insert the SD card into the card reader and plug it in.

### 1.2 Choose the device, OS and storage

In Imager select:

| Setting | Choose |
|---|---|
| **Device** | Raspberry Pi 4 (this entry covers the Compute Module 4) |
| **OS** | Other general-purpose OS → Ubuntu → **Ubuntu Server 22.04.x LTS (64-bit)** |
| **Storage** | your SD card |

> Pick **Server**, not Desktop, and **22.04**, not 24.04. ROS 2 `ros-base` needs no desktop,
> and a server image leaves more RAM for your robot code.

### 1.3 OS customisation — this replaces the monitor setup

The CM4 runs without a monitor ("headless"), so everything the first-boot wizard would ask
is set in Imager. When Imager asks **"Would you like to apply OS customisation settings?"**,
choose **Edit settings**. Newer Imager versions show these as steps in the wizard instead.

| Tab | Setting | Value |
|---|---|---|
| General | Hostname | a unique name, e.g. `cm4-01` (missed it? see Part 2.1) |
| General | Username / password | e.g. `ubuntu` / a password you will remember |
| General | Wireless LAN | your Wi-Fi SSID + password + **Wireless LAN country** (e.g. `CA`) — skip if `W` = 0 |
| General | Locale | your time zone and keyboard layout |
| Services | Enable SSH | ✅ *Use password authentication* |

This guide uses hostname **`cm4-01`** and user **`ubuntu`** in its examples. Use your own
values wherever you see them.

Click **Save**, then **Yes** to apply the settings, then **Write**. The write and verify take about 5–10 minutes.

> **Wi-Fi is optional here, but it helps.** If you give the CM4 a Wi-Fi network, it gets
> internet on first boot and you can find it through your router. You can always switch to
> Ethernet-only later (Part 4).

---

## Part 2 — First Boot

1. Insert the SD card into the IO board's micro-SD slot.
2. Plug an Ethernet cable between the IO board and your laptop, or your router.
3. Connect the **12 V** supply. The green activity LED flickers while the SD card is being read.

**Wait 3–5 minutes.** On first boot Ubuntu's `cloud-init` applies your Imager settings:
it creates your user, sets the hostname, joins Wi-Fi and enables SSH. It may reboot once
while it does this. If you try to log in too early, you get `Permission denied` even with
the right password. Wait, then try again.

> **What about a monitor?** You don't need one. If you want to watch the boot, plug
> HDMI into **HDMI0** and a USB keyboard into the IO board's USB ports. Ubuntu's
> `/boot/firmware/config.txt` normally already contains `dtoverlay=dwc2,dr_mode=host`
> under `[cm4]`, which turns those USB ports on. On the CM4 they are off by default.

### 2.1 Set the hostname (monitor + keyboard)

If you skipped the hostname in Imager, the CM4 boots as **`ubuntu`**, and every CM4 on the
network then has the same name. Set a unique name at the CM4's own console.

**1. Connect a monitor and keyboard.** With the power off, plug an HDMI monitor into
**HDMI0** on the IO board and a USB keyboard into one of its USB ports. Then power on.

**2. Log in at the text console.** Ubuntu Server has no desktop. After the boot messages,
wait for the `cloud-init` lines to stop, then press **Enter** to get a login prompt:

```
cm4-01 login: ubuntu
Password:
```

- **If you set a user in Imager**, log in with that username and password.
- **If you skipped customisation entirely**, the default login is `ubuntu` / `ubuntu`. Ubuntu
  then makes you change it right away: type the current password (`ubuntu`) once, then your
  new password twice.

> The password doesn't show while you type, not even as `*`. That is normal.

**3. Check the current name:**

```bash
hostnamectl
```

**4. Set the new name.** Use lowercase letters, digits and `-` only, e.g. `cm4-01`:

```bash
sudo hostnamectl set-hostname cm4-01
```

**5. Update `/etc/hosts`,** so `sudo` doesn't warn *"unable to resolve host cm4-01"*:

```bash
sudo nano /etc/hosts
```

Change the `127.0.1.1` line to your new name (add the line if it is missing):

```
127.0.0.1 localhost
127.0.1.1 cm4-01
```

Save with `Ctrl+O`, `Enter`, then exit with `Ctrl+X`.

**6. Stop cloud-init from changing the name back on the next boot:**

```bash
echo "preserve_hostname: true" | sudo tee /etc/cloud/cloud.cfg.d/99-preserve-hostname.cfg
```

**7. Reboot and check:**

```bash
sudo reboot
# log in again, then:
hostname          # -> cm4-01
```

While you are at the console, note the CM4's IP address. It saves searching for it in Part 3.2:

```bash
ip -br addr       # e.g. eth0  UP  192.168.137.57/24
```

> **Later changes over SSH:** the same steps (3–7) work in an SSH session too. If you
> have already installed `avahi-daemon` (Part 4.2), also run
> `sudo systemctl restart avahi-daemon` so that `<new-name>.local` resolves.

---

## Part 3 — Connect from your laptop

### 3.1 Share internet from your laptop to the CM4 (over Ethernet)

This lets the CM4 reach the internet through your laptop's Wi-Fi. It also gives you a
direct cable link that works on any network, including campus Wi-Fi that blocks
device-to-device traffic.

For the **first connection**, use the built-in GUI sharing. It also runs a DHCP server,
so the CM4 gets an address automatically:

| Your laptop | How | CM4 gets an address in |
|---|---|---|
| **Windows** | Control Panel → Network Connections → right-click *Wi-Fi* → Properties → Sharing → allow sharing with *Ethernet* | `192.168.137.x` |
| **macOS** | System Settings → General → Sharing → Internet Sharing: share *Wi-Fi* to *Ethernet/USB LAN* | `192.168.2.x` |
| **Linux (NetworkManager)** | Wired connection settings → IPv4 → **Shared to other computers** | `10.42.0.x` |

**Windows:**

<a href="https://youtu.be/Tc5ONryOa1A?si=qv7NKpMUDXcuS7nK" target="_blank">
  <img src="https://img.youtube.com/vi/Tc5ONryOa1A/hqdefault.jpg" alt="Internet sharing Windows" style="max-width:100%;">
</a>

**macOS:**

<a href="https://www.youtube.com/watch?v=tY1-dS3cICc" target="_blank">
  <img src="https://img.youtube.com/vi/tY1-dS3cICc/hqdefault.jpg" alt="Internet sharing macOS" style="max-width:100%;">
</a>

#### Script alternative (optional)

These scripts do the same thing from a terminal. Each one has a **SETTINGS block at the
top**: edit the adapter names and IP addresses to match your laptop before running it.

| Your laptop | Script | Run it with |
|---|---|---|
| Windows | ⬇️ [share_internet_windows.ps1](code/share_internet_windows.ps1) | PowerShell **as Administrator** |
| macOS | ⬇️ [share_internet_macos.sh](code/share_internet_macos.sh) | Terminal |
| Linux | ⬇️ [share_internet_linux.sh](code/share_internet_linux.sh) | Terminal |

```bash
# macOS / Linux: list adapters first, then turn sharing on (--undo turns it off)
bash share_internet_linux.sh --list
sudo bash share_internet_linux.sh
```

```powershell
# Windows - PowerShell as Administrator (-List, -Undo)
powershell -ExecutionPolicy Bypass -File share_internet_windows.ps1 -List
powershell -ExecutionPolicy Bypass -File share_internet_windows.ps1
```

> **The macOS and Linux scripts do NOT hand out addresses** (no DHCP). They only work once
> the CM4 has the matching static IP from Part 4.1. Use the GUI method first.
> On Windows, ICS always uses `192.168.137.1` for the laptop, so the script and the GUI behave the same.

> **Sharing is cleared when your laptop reboots.** Turn it on again each session.

### 3.2 Find the CM4's IP address

Ubuntu Server doesn't advertise `cm4-01.local` until you install `avahi-daemon`
(Part 4.2), so for the first login you need the IP address. Pick one way:

| Where the CM4 is | How to find it |
|---|---|
| Cable to a **Windows** laptop (ICS) | PowerShell: `arp -a` and look under the `192.168.137.1` interface |
| Cable to a **macOS** laptop | Terminal: `arp -a \| grep 192.168.2` |
| Cable to a **Linux** laptop (Shared) | `ip neigh show dev <ethernet-if>` or `cat /var/lib/NetworkManager/dnsmasq-*.leases` |
| Same Wi-Fi / router | the router's "connected devices" page, looking for `cm4-01` |
| Any of the above | `nmap -sn 192.168.137.0/24` (use your subnet) |

### 3.3 SSH in

```bash
ssh ubuntu@<CM4_IP>          # e.g. ssh ubuntu@192.168.137.57
```

Type `yes` to accept the host key the first time, then your password.

> **"REMOTE HOST IDENTIFICATION HAS CHANGED"** after re-flashing is expected: the new OS
> has new keys. Clear the old one with `ssh-keygen -R <CM4_IP>` (and `ssh-keygen -R cm4-01.local`).

### 3.4 Log in without a password (SSH keys)

From your **laptop** (not the CM4):

```bash
ssh-keygen -t ed25519                  # press Enter to accept the defaults
ssh-copy-id ubuntu@<CM4_IP>            # macOS / Linux
```

On Windows, where `ssh-copy-id` doesn't exist, run this in PowerShell:

```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh ubuntu@<CM4_IP> "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 3.5 VS Code Remote-SSH

For a graphical editor on files that live on the CM4, install the **Remote - SSH**
extension in VS Code and connect to `ubuntu@<CM4_IP>`:

<a href="https://youtu.be/RLd6qgRHVh0" target="_blank">
  <img src="https://img.youtube.com/vi/RLd6qgRHVh0/hqdefault.jpg" alt="SSH with VSCode" style="max-width:100%;">
</a>

### 3.6 Get the lab scripts onto the CM4

On the **CM4**, now that it has internet:

```bash
mkdir -p ~/lab01 && cd ~/lab01
for f in setup_network.sh setup_swap.sh check_system.sh led_blink.py button_led.py; do
  curl -fsSLO {{ site.github.url }}/Lab_01/code/$f
done
ls
```

If the CM4 has no internet yet, download the files from this page and copy them over from your laptop:

```bash
scp setup_network.sh setup_swap.sh check_system.sh led_blink.py button_led.py ubuntu@<CM4_IP>:~/lab01/
```

---

## Part 4 — Networking

Ubuntu Server doesn't use `/etc/dhcpcd.conf` (a Raspberry Pi OS file). Networking is set by
**netplan** YAML files in `/etc/netplan/`. The script below writes that file for you.

### 4.1 Static IP on eth0

A fixed Ethernet address means you always SSH to the same IP over the cable.
**Use the row that matches how your laptop shares internet:**

| Laptop sharing method | `ETH_ADDRESS` | `ETH_GATEWAY` |
|---|---|---|
| **Windows** ICS (GUI or script) | `192.168.137.12/24` | `192.168.137.1` |
| **macOS** Internet Sharing (GUI) | `192.168.2.12/24` | `192.168.2.1` |
| **Linux** NetworkManager "Shared" (GUI) | `10.42.0.12/24` | `10.42.0.1` |
| **macOS / Linux** script | `192.168.0.12/24` | `192.168.0.1` |

⬇️ [setup_network.sh](code/setup_network.sh)

On the CM4:

```bash
cd ~/lab01
nano setup_network.sh          # edit ETH_ADDRESS / ETH_GATEWAY in the SETTINGS block
sudo bash setup_network.sh
```

The script:
- backs up the current netplan files and writes one file, `/etc/netplan/01-cm4-network.yaml`
- keeps the Wi-Fi network you set in Imager (`WIFI_MODE="keep"`)
- validates the file with `netplan generate` before applying it, and restores the backup if it fails
- stops cloud-init from rewriting the network config on later boots

If you were connected over the cable, your SSH session drops. Reconnect to the new address:

```bash
ssh ubuntu@192.168.137.12      # the ETH_ADDRESS you chose
ping -c3 8.8.8.8               # on the CM4: internet works?
```

Here is the file it writes, for reference (Windows row):

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      optional: true            # don't stall boot for 2 min when the cable is out
      dhcp4: false
      addresses: [192.168.137.12/24]
      routes:
        - to: default
          via: 192.168.137.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```

> **Plugging eth0 into a router instead of your laptop?** Set `ETH_MODE="dhcp"` and re-run
> the script. A static `192.168.137.12` has no route on a normal router network.

Other options: `sudo bash setup_network.sh --show` prints the current config, and
`--restore` puts the previous one back.

### 4.2 Reach the CM4 by name (`cm4-01.local`)

```bash
sudo apt update
sudo apt install -y avahi-daemon
```

From now on `ssh ubuntu@cm4-01.local` works from macOS, Linux and Windows 10/11 on the same network.

### 4.3 Optional — Wi-Fi hotspot on the CM4

Make the CM4 broadcast its own Wi-Fi network so a laptop can connect with no router or
cable. **Do this while connected over Ethernet.** Hotspot mode replaces the Wi-Fi client
connection, so the CM4 then gets internet only through eth0.

In the SETTINGS block of `setup_network.sh`:

```bash
WIFI_MODE="ap"
AP_SSID="$(hostname)"         # the network name = your hostname, e.g. cm4-01
AP_PASSWORD="choose-8+-chars"
```

```bash
sudo bash setup_network.sh
```

The script installs **NetworkManager**, which netplan needs to run a hotspot, and runs it on
wlan0 only. eth0 stays on the default networking service, systemd-networkd. Join the
`cm4-01` Wi-Fi network from your laptop, then:

```bash
ssh ubuntu@10.42.0.1
```

To go back to a Wi-Fi client, set `WIFI_MODE="client"` plus `WIFI_SSID` / `WIFI_PASSWORD`
and run the script again.

---

## Part 5 — Update the System

```bash
sudo apt update
sudo apt full-upgrade -y
sudo reboot
```

> **`Could not get lock /var/lib/dpkg/lock-frontend`**: on the first boot,
> `unattended-upgrades` installs security updates in the background. Wait a few minutes
> for it to finish. Don't delete the lock file.

Check the clock. Most CM4 setups have no battery-backed clock, and a wrong date makes `apt`
reject repositories with *"Release file is not valid yet"*:

```bash
timedatectl                                    # "System clock synchronized: yes"
sudo timedatectl set-timezone America/Vancouver    # use your own zone: timedatectl list-timezones
```

### 5.1 Optional — IO board real-time clock

The IO board has a **PCF85063A RTC** and a CR2032 battery holder, but Ubuntu doesn't enable it.
With a battery fitted, the CM4 keeps the right time without internet, which is useful for
timestamped ROS bags recorded in the field.

```bash
sudo nano /boot/firmware/config.txt
# add at the end, under [all]:
dtoverlay=i2c-rtc,pcf85063a,i2c_csi_dsi
```

```bash
sudo reboot
sudo hwclock -r      # read the RTC
sudo hwclock -w      # once NTP has set the correct time, write it to the RTC
```

---

## Part 6 — Linux Command Practice

Practice these on the CM4.

| Command | What it does |
|---------|-------------|
| `ls -la` | List files with details, including hidden ones |
| `cd <dir>` / `cd ..` / `cd ~` | Change directory / up one level / home |
| `pwd` | Print the current directory |
| `mkdir <name>` | Create a directory |
| `cp <src> <dst>` / `mv <src> <dst>` | Copy / move or rename |
| `rm <file>` | Delete a file |
| `cat <file>` / `nano <file>` | Print a file / edit it in the terminal |
| `sudo <command>` | Run as administrator |
| `sudo apt install <pkg>` | Install a package |
| `ip -br addr` | Show network interfaces and IPs |
| `free -h` / `df -h` | Memory / disk usage |
| `htop` | Live CPU and memory monitor (`q` quits) |
| `systemctl status <service>` | Is a service running? (e.g. `ssh`) |
| `journalctl -u <service> -e` | Logs of a service |
| `Ctrl+C` | Stop a running program |

**Exercises:**
1. Go to your home directory and list all files, including hidden ones.
2. Create a directory `practice`, enter it, and create `hello.txt` with `nano`.
3. Copy `hello.txt` to `hello_copy.txt`, then delete `hello_copy.txt`.
4. Find out how much RAM and free disk space your CM4 has.
5. Check that the `ssh` service is running and view its last log lines.

---

## Part 7 — Memory Swap

Installing ROS 2 from `apt` needs little memory. **Building** packages with `colcon`
(C++ nodes especially) can run a 1–4 GB CM4 out of memory, and the compiler gets killed
partway through. Ubuntu Server has no swap by default, so add some.

⬇️ [setup_swap.sh](code/setup_swap.sh)

```bash
cd ~/lab01
sudo bash setup_swap.sh
```

This sets up both kinds of swap:
- **zram**: compressed swap in RAM. It's fast and doesn't wear the SD card.
- **a 2 GB `/swapfile`** on the SD card, as a safety net for long builds.

It prints RAM + swap at the end. Aim for at least **4 GB** in total before building ROS 2 packages.

```bash
sudo bash setup_swap.sh --status      # check any time
sudo bash setup_swap.sh --uninstall   # undo
```

> **SD card wear:** the swap file is only used when RAM and zram are full, so normal use
> barely touches it. On a 1–2 GB CM4, you can also build with
> `colcon build --parallel-workers 1` to keep memory use down.

---

## Part 8 — Verify the Hardware: LED and Button on the GPIO Header

This replaces a "hello world" demo: you prove the CM4 can drive an output and read an input
on the IO board's **40-pin GPIO header**, the same one your robot's sensors and drivers
will use.

### 8.1 Install the GPIO tools

On Ubuntu, use **libgpiod**. `RPi.GPIO` and `raspi-gpio` are Raspberry Pi OS tools.

```bash
sudo apt install -y gpiod python3-libgpiod
gpiodetect                 # expect: gpiochip0 [pinctrl-bcm2711] (58 lines)
gpioinfo gpiochip0 | head -30
```

**Permissions:** check which group owns the GPIO device and add yourself to it:

```bash
ls -l /dev/gpiochip0                  # e.g. crw-rw---- 1 root dialout ...
sudo usermod -aG dialout $USER        # use the group shown above
# log out and back in (exit, then ssh again) for the group to apply
```

If `ls` shows `root root`, run the GPIO commands below with `sudo`.

### 8.2 Wire the circuit

**Power off first**: `sudo poweroff`, wait for the activity LED to stop, then unplug 12 V.

The header uses **3.3 V logic**. Never connect 5 V to a GPIO pin.

```
  40-pin header (pin 1 is marked on the IO board)

         3V3  (1) (2)  5V
       GPIO2  (3) (4)  5V
       GPIO3  (5) (6)  GND
       GPIO4  (7) (8)  GPIO14
         GND  (9) (10) GPIO15
  ┌─── GPIO17 (11) (12) GPIO18
  │ ┌─ GPIO27 (13) (14) GND ────────┐
  │ │                               │
  │ └──────────[ button ]───────────┘
  │
  └──[ 330 Ω ]──►|── GND (pin 9)
                LED
          long leg (anode) toward the resistor,
          short leg (cathode) to GND
```

| Part | From | To |
|---|---|---|
| Resistor | header **pin 11** (GPIO17) | LED long leg (anode) |
| LED short leg (cathode) | | header **pin 9** (GND) |
| Button | header **pin 13** (GPIO27) | header **pin 14** (GND) |

The button needs no resistor, because the program turns on the CM4's internal pull-up.

Power the board back on and SSH in.

### 8.3 Test from the command line

```bash
gpioset --mode=wait gpiochip0 17=1   # LED on until you press Enter
gpioset gpiochip0 17=0               # make sure it is off
gpioget -B pull-up gpiochip0 27    # button: 1 = released, 0 = pressed
```

These are **libgpiod 1.6** commands, the version in Ubuntu 22.04. Newer guides show v2
syntax (`gpioset -c gpiochip0 17=1`), which doesn't work here.

### 8.4 Test from Python

⬇️ [led_blink.py](code/led_blink.py) · ⬇️ [button_led.py](code/button_led.py)

```bash
cd ~/lab01
python3 led_blink.py            # LED blinks 10 times
python3 button_led.py           # LED lights while you hold the button; Ctrl+C to stop
```

The core of `led_blink.py`:

```python
import gpiod

chip = gpiod.Chip("gpiochip0")
led = chip.get_line(17)                               # BCM GPIO17 = header pin 11
led.request(consumer="led_blink", type=gpiod.LINE_REQ_DIR_OUT, default_vals=[0])
led.set_value(1)                                      # on
```

**If the LED doesn't light:** flip it around (LEDs only conduct one way), check you are on
**pin 11** (a GPIO number is not a pin number), and check the resistor is 330 Ω, not 330 kΩ.

**Exercise:** change `button_led.py` so each press *toggles* the LED instead of lighting it only while you hold the button.

---

## Part 9 — Prepare for ROS 2 Humble

These are the first steps of the official ROS 2 Humble install. Doing them now means the
ROS 2 install later is only the ROS-specific part.

### 9.1 UTF-8 locale

```bash
locale                                    # look for UTF-8
sudo apt install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
```

### 9.2 Universe repository and basic tools

```bash
sudo apt install -y software-properties-common
sudo add-apt-repository -y universe
sudo apt install -y curl git htop
```

### 9.3 Run the readiness check

⬇️ [check_system.sh](code/check_system.sh)

```bash
cd ~/lab01
bash check_system.sh
```

It changes nothing. It prints **PASS / WARN / FAIL** for the model, Ubuntu version and
architecture, swap, disk space, network, DNS, clock, apt, locale and GPIO. When it ends with
**"This CM4 is ready for ROS 2 Humble"**, this lab is done.

### Next: installing ROS 2

In the next lab you will follow the official guide,
[ROS 2 Humble — Ubuntu (deb packages)](https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debs.html),
and install **`ros-humble-ros-base`**, not `ros-humble-desktop`. The desktop variant pulls in
RViz and GUI tools that a headless CM4 can't use. Visualise from your laptop instead.

---

## Troubleshooting

| Problem | Try this |
|---------|---------|
| Nothing happens at power-on, no activity LED | Check the 12 V supply; make sure the J2 jumper is **not** fitted; re-seat the CM4 |
| CM4 doesn't boot from the SD card | Check it is a **Lite** model (part number ends in `000`). eMMC models ignore the SD slot |
| `Permission denied` at the first SSH login | cloud-init hasn't finished. Wait 2–3 minutes and try again |
| `sudo: unable to resolve host ...` | `/etc/hosts` still has the old name on the `127.0.1.1` line (Part 2.1, step 5) |
| Hostname goes back to `ubuntu` after a reboot | Add `preserve_hostname: true` (Part 2.1, step 6) |
| `ssh: Could not resolve hostname cm4-01.local` | Install `avahi-daemon` (Part 4.2) or use the IP address |
| Can't find the CM4's IP | Use the GUI sharing method (it runs DHCP), then `arp -a`; or plug in HDMI + keyboard and run `ip -br addr` |
| Lost SSH after `setup_network.sh` | Reconnect to `ETH_ADDRESS`. If that fails, put the SD card in your laptop, delete `/etc/netplan/01-cm4-network.yaml` on the `writable` partition and copy the backup from `/etc/netplan-backups/` |
| Weak or no Wi-Fi | The CM4 uses its PCB antenna by default. If an external antenna is fitted, add `dtparam=ant2` to `/boot/firmware/config.txt` |
| `Could not get lock /var/lib/dpkg/lock-frontend` | unattended-upgrades is running. Wait |
| `Release file ... is not valid yet` | The clock is wrong. Check `timedatectl`, internet, and Part 5.1 |
| USB keyboard doesn't work on the IO board | Check `/boot/firmware/config.txt` has `dtoverlay=dwc2,dr_mode=host` |
| `gpioset: error ... Permission denied` | Part 8.1 permissions, or use `sudo` |
| `gpioset: unrecognized option '-c'` | That is v2 syntax. Use `gpioset gpiochip0 17=1` on 22.04 |
| Build killed / `c++: fatal error: Killed signal` | Out of memory. Part 7, then `colcon build --parallel-workers 1` |

---

## Completion Checklist

- [ ] SD card flashed with Ubuntu Server 22.04 LTS (64-bit), with hostname, user, SSH and Wi-Fi set in Imager
- [ ] CM4 Lite boots on the IO board from 12 V (J2 not fitted)
- [ ] Unique hostname set: `hostname` prints e.g. `cm4-01`
- [ ] Connected over SSH from your laptop (key-based login set up)
- [ ] Internet shared from the laptop: `ping -c3 8.8.8.8` works on the CM4
- [ ] Static IP on eth0 via `setup_network.sh` (e.g. `192.168.137.12`)
- [ ] `avahi-daemon` installed: `ssh ubuntu@cm4-01.local` works
- [ ] *(optional)* Wi-Fi hotspot running (SSID = hostname)
- [ ] System fully updated and clock synchronised
- [ ] Linux command exercises completed
- [ ] Swap configured: `sudo bash setup_swap.sh --status`
- [ ] LED blinks and button lights the LED (`led_blink.py`, `button_led.py`)
- [ ] UTF-8 locale and `universe` repository set up
- [ ] `bash check_system.sh` reports **ready for ROS 2 Humble**
