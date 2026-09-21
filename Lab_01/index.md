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
| Services | Enable SSH | ✅ *Use password authentication* (skipped? see Part 3.3.1) |

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
ubuntu login: ubuntu
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

> **The macOS and Linux scripts do NOT hand out addresses** (no DHCP). The CM4 then has no
> IPv4 address until you give it the matching static IP (Part 4.1). You can still reach it
> over **IPv6 link-local** (Part 3.2.2) to do that, or set it at the CM4's console (Part 4.1, Method A).
> On Windows, ICS always uses `192.168.137.1` for the laptop, so the script and the GUI behave the same.

> **Sharing is cleared when your laptop reboots.** Turn it on again each session.

### 3.2 Find the CM4's IP address

Ubuntu Server doesn't advertise `cm4-01.local` until you install `avahi-daemon`
(Part 4.2), so for the first login you need an address. Which method works depends on
whether your laptop **hands out** addresses on the cable (DHCP):

| Laptop sharing | Does the CM4 get an IPv4 address? | Use |
|---|---|---|
| Windows ICS, macOS Internet Sharing, Linux "Shared to other computers" (GUI) | Yes, automatically | **3.2.1**, IPv4 |
| `share_internet_*.sh` scripts, or a laptop port set to a manual IP | **No.** The CM4 sits waiting for an address that never comes | **3.2.2**, IPv6 link-local |
| CM4 joined Wi-Fi (set in Imager) | Yes, from the router | router's "connected devices" page, looking for `cm4-01` |

**How to recognise the CM4:** its hardware (MAC) address starts with a Raspberry Pi prefix:
`d8:3a:dd`, `dc:a6:32`, `e4:5f:01`, `28:cd:c1`, `2c:cf:67` or `b8:27:eb`.
Windows shows these with dashes, e.g. `d8-3a-dd-…`.

#### 3.2.1 IPv4: when the laptop hands out addresses

| Laptop | Command | Look for |
|---|---|---|
| **Windows** (ICS) | PowerShell: `arp -a` | under `Interface: 192.168.137.1`, a `192.168.137.x` entry with a Pi MAC |
| **macOS** | Terminal: `arp -a \| grep 192.168.2` | a `192.168.2.x` entry with a Pi MAC |
| **Linux** (Shared) | `ip neigh show dev <ethernet-if>` | a `10.42.0.x` entry with a Pi MAC |
| any | `nmap -sn 192.168.137.0/24` (use your range) | a host with a Pi MAC |

#### 3.2.2 IPv6 link-local: works even when the CM4 has no IPv4 at all

Every Ethernet port gives itself an **IPv6 link-local address** (it starts with `fe80::`) as
soon as a cable is plugged in. It doesn't need DHCP, a router or any setup. Ubuntu builds
it from the MAC address, so it **never changes**. That makes it a reliable way into a
CM4 that has no IPv4 address, or the wrong one.

The trick is to ping **`ff02::1`**, the IPv6 "everyone on this cable" address, and see who replies.

**1. Find the name of your laptop's Ethernet interface.** A link-local address only means
something together with the interface it lives on.

| Laptop | Command | Typical name |
|---|---|---|
| **Linux** | `ip -br link` | `enp130s0`, `eth0`, `enx…` (USB adapter) |
| **macOS** | `networksetup -listallhardwareports` | `en5`, `en6`, `en7` (USB-C Ethernet adapter) |
| **Windows** | PowerShell: `Get-NetAdapter` | use the **ifIndex** number of *Ethernet*, e.g. `12` |

**2. Ping everyone on the cable, then list who answered.** Replace `enp130s0`, `en5` or `12` with yours:

**Linux:**

```bash
ping -6 -c3 ff02::1%enp130s0
ip -6 neigh show dev enp130s0
```

**macOS:**

```bash
ping6 -c3 ff02::1%en5
ndp -an | grep en5
```

**Windows (PowerShell):**

```powershell
ping -6 -n 3 ff02::1%12
Get-NetNeighbor -InterfaceIndex 12 -AddressFamily IPv6 | Where-Object LinkLayerAddress -ne "" | Format-Table IPAddress, LinkLayerAddress, State
```

**3. Pick out the CM4.** One of the replies is the laptop itself. The CM4's line shows a Pi MAC (the state at the end may say `REACHABLE`, `STALE` or `DELAY`; any of them is fine). Example from a Linux laptop:

```
$ ping -6 -c3 ff02::1%enp130s0
64 bytes from fe80::6914:41ea:6e9:c4a0%enp130s0: icmp_seq=1 ttl=64 time=0.046 ms   <- the laptop
64 bytes from fe80::da3a:ddff:fe45:dcb7%enp130s0: icmp_seq=1 ttl=64 time=0.540 ms  <- the CM4
$ ip -6 neigh show dev enp130s0
fe80::da3a:ddff:fe45:dcb7 lladdr d8:3a:dd:45:dc:b7 REACHABLE                       <- Pi MAC
```

**4. Use it: always add `%<interface>` at the end.**

```bash
ssh ubuntu@fe80::da3a:ddff:fe45:dcb7%enp130s0                  # Windows: ...%12
scp setup_network.sh 'ubuntu@[fe80::da3a:ddff:fe45:dcb7%enp130s0]:~/lab01/'   # scp needs [ ] and quotes
```

Now use Part 4.1 to give the CM4 a proper IPv4 address in your laptop's range.

> **Is SSH even running?** Check the port before you worry about passwords:
> `nc -zv fe80::da3a:ddff:fe45:dcb7%enp130s0 22` (Linux/macOS) should report *succeeded* / *open*.
> On Windows: `Test-NetConnection fe80::da3a:ddff:fe45:dcb7%12 -Port 22`.

> **Nothing but the laptop answers?** Check the cable and the IO board's Ethernet LEDs, and
> give the CM4 a few minutes after power-on. On Windows, the neighbour list sometimes stays
> empty even when the CM4 is there. In that case, use the monitor and run `ip -br addr` on the CM4 (Part 2.1).

### 3.3 SSH in

```bash
ssh ubuntu@<CM4_IP>          # e.g. ssh ubuntu@192.168.137.57, or the fe80::…%<if> address
```

Use the username you set in Imager. Type `yes` to accept the host key the first time, then your password.

> **"REMOTE HOST IDENTIFICATION HAS CHANGED"** after re-flashing is expected: the new OS
> has new keys. Clear the old one with `ssh-keygen -R <CM4_IP>` (and `ssh-keygen -R cm4-01.local`).

#### 3.3.1 `Permission denied (publickey)`: turn on password login

```
$ ssh ubuntu@fe80::da3a:ddff:fe45:dcb7%enp130s0
ubuntu@fe80::da3a:ddff:fe45:dcb7%enp130s0: Permission denied (publickey).
```

This means the CM4 **accepts only SSH keys, not passwords**, and it doesn't trust your laptop's key.
Ubuntu's image switches password login off unless Imager's *Enable SSH → Use password
authentication* setting was applied. Turn it on at the CM4's own console:

**1.** Connect the monitor and keyboard and log in (Part 2.1). Confirm your username, since you need it for SSH:

```bash
whoami
```

**2.** See which file turns passwords off:

```bash
sudo grep -ri passwordauthentication /etc/ssh/sshd_config /etc/ssh/sshd_config.d/
# typically: /etc/ssh/sshd_config.d/50-cloud-init.conf:PasswordAuthentication no
```

**3.** Override it. The SSH server uses the **first** value it reads, and it reads the files in
`sshd_config.d/` in name order, so a file starting with `01-` wins over `50-cloud-init.conf`:

```bash
echo "PasswordAuthentication yes" | sudo tee /etc/ssh/sshd_config.d/01-password-auth.conf
sudo systemctl restart ssh
sudo sshd -T | grep -i passwordauthentication     # -> passwordauthentication yes
```

**4.** From the laptop, try again. It now asks for your password:

```bash
ssh <username>@<CM4_IP>
```

Next, set up SSH keys (Part 3.4). After that you can switch password login off again for
security with `sudo rm /etc/ssh/sshd_config.d/01-password-auth.conf && sudo systemctl restart ssh`.

> **Wrong username gives the same error.** If the account doesn't exist, SSH still says
> `Permission denied (publickey)` when passwords are off. Check it with `whoami` at the console.

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

Several later steps run a script **on the CM4**. The scripts are published on this site, so
they start out on the internet and not on the CM4. Use whichever of these three ways fits
your situation:

| Way | Needs | Best when |
|---|---|---|
| **A. Download on the CM4** (`curl`) | CM4 has internet | You can SSH in and `ping 8.8.8.8` works on the CM4 |
| **B. Copy from your laptop** (`scp`) | SSH from laptop to CM4 | You can SSH in, but the CM4 has no internet |
| **C. Copy via the SD card** | Nothing: no network at all | You can't SSH in yet (e.g. the CM4 isn't in your laptop's range) |

#### A. Download directly on the CM4

In an SSH session or at the CM4's console:

```bash
mkdir -p ~/lab01 && cd ~/lab01
for f in setup_network.sh setup_swap.sh check_system.sh led_blink.py button_led.py; do
  curl -fsSLO {{ site.github.url }}/Lab_01/code/$f
done
ls
```

#### B. Copy from your laptop with `scp`

1. On your **laptop**, click the ⬇️ links on this page to download the scripts. They land in
   your `Downloads` folder: [setup_network.sh](code/setup_network.sh),
   [setup_swap.sh](code/setup_swap.sh), [check_system.sh](code/check_system.sh),
   [led_blink.py](code/led_blink.py), [button_led.py](code/button_led.py).
   If the browser opens the file as text instead, right-click the link → **Save link as…**
2. Open a terminal on the **laptop**. On Windows use PowerShell. Go to the Downloads folder:

   ```bash
   cd ~/Downloads             # Windows PowerShell: cd $HOME\Downloads
   ```

3. Create the folder on the CM4, then copy the files into it. Replace `<CM4_IP>` with its address:

   ```bash
   ssh ubuntu@<CM4_IP> "mkdir -p ~/lab01"
   scp setup_network.sh setup_swap.sh check_system.sh led_blink.py button_led.py ubuntu@<CM4_IP>:~/lab01/
   ```

4. Check on the CM4: `ls ~/lab01`

#### C. Copy through the SD card (no network needed)

The SD card's first partition, **`system-boot`**, is a normal FAT drive that Windows, macOS and
Linux can all read and write. Anything you copy there shows up on the CM4 under `/boot/firmware/`.

1. On the CM4 run `sudo poweroff`, wait until the activity LED stops, unplug the 12 V supply, and take out the SD card.
2. Put the SD card in your laptop. A drive called **`system-boot`** appears.
   > **Windows may also say *"You need to format the disk in drive X: before you can use it"*.**
   > That is the Linux partition, which Windows can't read. Click **Cancel**. Formatting
   > it would erase Ubuntu.
3. Drag the downloaded scripts onto the `system-boot` drive, then **eject** it properly before removing the card.
4. Put the card back in the IO board and power on. At the CM4 console, or over SSH:

   ```bash
   mkdir -p ~/lab01
   cp /boot/firmware/*.sh /boot/firmware/*.py ~/lab01/
   ls ~/lab01
   ```

---

## Part 4 — Networking

Ubuntu Server doesn't use `/etc/dhcpcd.conf` (a Raspberry Pi OS file). Networking is set by
**netplan** YAML files in `/etc/netplan/`.

### 4.1 Static IP on eth0, in your laptop's shared range

When your laptop shares its internet over Ethernet, the cable becomes a small network with
the **laptop as the gateway**. The CM4 must have an address on that same network, meaning the
same first three numbers, and must use the laptop's address as its gateway. A fixed
(static) address also means you always SSH to the same IP.

#### Step 1 — Find your laptop's address on the Ethernet link

Turn internet sharing on (Part 3.1) with the cable plugged in, then on the **laptop**:

| Laptop | Command | Look for |
|---|---|---|
| **Windows** | `ipconfig` (PowerShell) | the *Ethernet adapter* section → **IPv4 Address**, e.g. `192.168.137.1` |
| **macOS** | `ifconfig bridge100 \| grep "inet "` (GUI sharing) or `ifconfig en5 \| grep "inet "` (script) | `inet 192.168.2.1` |
| **Linux** | `ip -br addr` | your Ethernet interface (`enp…`/`eth…`), e.g. `10.42.0.1/24` |

**The rule:** keep the first three numbers, change the last one to `12`.

| If the laptop is… | then the CM4 gets `ETH_ADDRESS` | and `ETH_GATEWAY` |
|---|---|---|
| `192.168.137.1` (Windows ICS) | `192.168.137.12/24` | `192.168.137.1` |
| `192.168.2.1` (macOS Internet Sharing) | `192.168.2.12/24` | `192.168.2.1` |
| `10.42.0.1` (Linux "Shared to other computers") | `10.42.0.12/24` | `10.42.0.1` |
| `192.168.0.1` (macOS / Linux script) | `192.168.0.12/24` | `192.168.0.1` |
| anything else, e.g. `a.b.c.1` | `a.b.c.12/24` | `a.b.c.1` |

Write your two values down. The examples below use the Windows row.

#### Step 2 — Set it on the CM4: pick Method A or B

| | Method A — at the CM4 console | Method B — the script over SSH |
|---|---|---|
| Needs | monitor + USB keyboard (Part 2.1) | an SSH session to the CM4 already working |
| Use it when | you **can't** reach the CM4 over the network yet | you **can** already SSH in: over Wi-Fi, via a GUI-sharing address, or over IPv6 link-local (Part 3.2.2) |

---

#### Method A — Write the netplan file by hand (monitor + keyboard)

This needs no network and no script: you type the config directly on the CM4.

**1.** Log in at the console (see Part 2.1) and look at the existing network files:

```bash
ls /etc/netplan/
# usually: 50-cloud-init.yaml   (written on first boot from your Imager settings)
```

**2.** Create a new file. Its name starts with `99-` so it is read *last* and overrides the
eth0 settings in `50-cloud-init.yaml`. Your Wi-Fi settings in that file are left alone.

```bash
sudo nano /etc/netplan/99-eth0-static.yaml
```

**3.** Type this in, using **your** values from Step 1:

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses: [192.168.137.12/24]
      routes:
        - to: default
          via: 192.168.137.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
      optional: true
```

> **YAML is strict about indentation.** Use **spaces, never Tab**, exactly 2 per level as
> shown. `addresses` and `routes` line up under `dhcp4`, and `- to:` is indented under `routes:`.

Save with `Ctrl+O`, `Enter`, then exit with `Ctrl+X`.

**4.** Lock down the file's permissions (netplan warns otherwise) and stop cloud-init from
rewriting the network config on later boots:

```bash
sudo chmod 600 /etc/netplan/99-eth0-static.yaml
echo "network: {config: disabled}" | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
```

**5.** Check the file, then apply it:

```bash
sudo netplan generate          # no output = no mistakes. An error names the line to fix.
sudo netplan apply
```

**6.** Test it:

```bash
ip -br addr show eth0          # -> eth0  UP  192.168.137.12/24
ping -c3 192.168.137.1         # the laptop answers?
ping -c3 8.8.8.8               # the internet answers?
```

**7.** From your **laptop**, you can now SSH in:

```bash
ssh ubuntu@192.168.137.12
```

**To undo Method A:** `sudo rm /etc/netplan/99-eth0-static.yaml && sudo netplan apply`

---

#### Method B — The `setup_network.sh` script (over SSH)

The script writes the same kind of netplan file, plus a backup, validation and the hotspot option (Part 4.3).

**1. Get the script onto the CM4** (details in [Part 3.6](#36-get-the-lab-scripts-onto-the-cm4)). The quickest way, run on your **laptop** from the folder you downloaded it to:

```bash
ssh ubuntu@<CURRENT_CM4_IP> "mkdir -p ~/lab01"
scp setup_network.sh ubuntu@<CURRENT_CM4_IP>:~/lab01/
```

With an IPv6 link-local address, `scp` needs brackets and quotes:
`scp setup_network.sh 'ubuntu@[fe80::…%enp130s0]:~/lab01/'`

⬇️ [setup_network.sh](code/setup_network.sh)

**2. SSH in and edit the SETTINGS block** with your values from Step 1:

```bash
ssh ubuntu@<CURRENT_CM4_IP>
cd ~/lab01
nano setup_network.sh
```

```bash
ETH_MODE="static"
ETH_ADDRESS="192.168.137.12/24"     # <- your value
ETH_GATEWAY="192.168.137.1"         # <- your value
```

**3. Run it:**

```bash
sudo bash setup_network.sh
```

The script:
- backs up the current netplan files and writes one file, `/etc/netplan/01-cm4-network.yaml`
- keeps the Wi-Fi network you set in Imager (`WIFI_MODE="keep"`)
- checks the new file with `netplan generate` before applying it, and restores the backup if the check fails
- stops cloud-init from rewriting the network config on later boots

**4. Reconnect.** If you were connected over the cable, the session drops when the address
changes. That is expected. From the laptop:

```bash
ssh ubuntu@192.168.137.12      # the ETH_ADDRESS you chose
ping -c3 8.8.8.8               # on the CM4: internet works?
```

> **Plugging eth0 into a router instead of your laptop?** With Method A, delete
> `99-eth0-static.yaml` and run `sudo netplan apply`. With Method B, set `ETH_MODE="dhcp"` and re-run
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
| Can't find the CM4's IP | Ping `ff02::1%<your-ethernet-if>` and use the CM4's `fe80::` address (Part 3.2.2); or plug in HDMI + keyboard and run `ip -br addr` |
| CM4 answers on IPv6 but has no `192.168.x.x` address | Your laptop doesn't hand out addresses (script or manual IP). SSH in over `fe80::…%<if>` and set the static IP (Part 4.1) |
| `Permission denied (publickey)` | Password login is off on the CM4. Turn it on at the console (Part 3.3.1), or check the username |
| Sharing works but the CM4 is in a different range from the laptop | Part 4.1: find the laptop's Ethernet address, then set the CM4's static IP (Method A needs only a monitor and keyboard) |
| `netplan generate` error about indentation or `mapping values` | A Tab or a wrong number of spaces in the YAML. Retype the indentation with spaces (Part 4.1, Method A step 3) |
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
