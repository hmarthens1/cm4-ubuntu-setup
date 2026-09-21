#!/bin/bash
# =============================================================================
# CM4 Lab 01 - Final check: is this CM4 ready for ROS 2 Humble?
# =============================================================================
# Read-only. Changes nothing. Prints PASS / WARN / FAIL for each item that the
# ROS 2 Humble (ros-humble-ros-base) install depends on.
#
# USAGE
#   bash check_system.sh
# =============================================================================

set -u
PASS=0; WARNS=0; FAILS=0
pass() { echo -e "  \033[1;32mPASS\033[0m  $*"; PASS=$((PASS+1)); }
warn() { echo -e "  \033[1;33mWARN\033[0m  $*"; WARNS=$((WARNS+1)); }
fail() { echo -e "  \033[1;31mFAIL\033[0m  $*"; FAILS=$((FAILS+1)); }
section() { echo -e "\n\033[1;36m$*\033[0m"; }

section "Hardware"
MODEL=$(tr -d '\0' < /proc/device-tree/model 2>/dev/null)
[[ "$MODEL" == *"Compute Module 4"* ]] && pass "$MODEL" || warn "Model is '${MODEL:-unknown}' - expected a Compute Module 4"
RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
pass "RAM: ${RAM_MB} MB"
ROOT_DEV=$(findmnt -n -o SOURCE /)
[[ "$ROOT_DEV" == /dev/mmcblk* ]] && pass "Root filesystem on $ROOT_DEV (SD card)" || warn "Root filesystem on $ROOT_DEV"
[ -e /dev/gpiochip0 ] && pass "GPIO: /dev/gpiochip0 present" || fail "No /dev/gpiochip0"
command -v gpioset >/dev/null && python3 -c "import gpiod" 2>/dev/null \
  && pass "libgpiod tools + python3-libgpiod installed" || warn "libgpiod missing - run: sudo apt install gpiod python3-libgpiod"
ls /dev/i2c-* >/dev/null 2>&1 && pass "I2C buses: $(ls /dev/i2c-* | tr '\n' ' ')" || warn "No /dev/i2c-* - check dtparam=i2c_arm=on in /boot/firmware/config.txt"
lsusb 2>/dev/null | grep -qv "root hub" && pass "USB devices seen on the IO board ports" || warn "No USB devices seen (fine if nothing is plugged in)"

section "Operating system"
. /etc/os-release
[ "${VERSION_CODENAME:-}" = "jammy" ] && pass "$PRETTY_NAME" || fail "$PRETTY_NAME - ROS 2 Humble needs Ubuntu 22.04 (jammy)"
ARCH=$(dpkg --print-architecture)
[ "$ARCH" = "arm64" ] && pass "Architecture: arm64" || fail "Architecture: $ARCH - use the 64-bit image"
pass "Hostname: $(hostname)"

section "Memory and storage"
TOTAL_MB=$(free -m | awk '/^Mem:/{m=$2} /^Swap:/{s=$2} END{print m+s}')
SWAP_MB=$(free -m | awk '/^Swap:/{print $2}')
[ "$SWAP_MB" -gt 0 ] && pass "Swap: ${SWAP_MB} MB (RAM + swap = ${TOTAL_MB} MB)" || warn "No swap - run setup_swap.sh"
FREE_MB=$(df -m / | awk 'NR==2{print $4}')
[ "$FREE_MB" -ge 4000 ] && pass "Free space on /: ${FREE_MB} MB" || warn "Only ${FREE_MB} MB free on / - ROS 2 plus a workspace wants 4 GB+"

section "Network"
ip -4 -br addr show eth0 2>/dev/null | grep -q UP && pass "eth0: $(ip -4 -br addr show eth0 | awk '{print $3}')" || warn "eth0 has no link"
ip -4 -br addr show wlan0 2>/dev/null | grep -q UP && pass "wlan0: $(ip -4 -br addr show wlan0 | awk '{print $3}')" || warn "wlan0 not connected (fine if you use Ethernet)"
ping -c2 -W3 8.8.8.8 >/dev/null 2>&1 && pass "Internet reachable (ping 8.8.8.8)" || fail "No internet - see Part 3.1 (share internet)"
getent hosts packages.ros.org >/dev/null 2>&1 && pass "DNS works (packages.ros.org resolves)" || fail "DNS lookup failed - check nameservers in setup_network.sh"
systemctl is-active --quiet avahi-daemon && pass "avahi-daemon running - $(hostname).local works" || warn "avahi-daemon not running - $(hostname).local will not resolve"
systemctl is-active --quiet ssh && pass "SSH server running" || fail "SSH server not running"

section "Time"
# The CM4 has no battery-backed clock on most carriers. A wrong date makes apt
# reject repository signatures ("Release file is not valid yet").
timedatectl show -p NTPSynchronized --value 2>/dev/null | grep -q yes \
  && pass "Clock synchronised: $(date '+%Y-%m-%d %H:%M %Z')" \
  || warn "Clock not NTP-synchronised yet: $(date '+%Y-%m-%d %H:%M %Z')"

section "Packages"
if pgrep -x unattended-upgr >/dev/null || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
  warn "apt is busy (unattended-upgrades) - wait for it before installing"
else
  pass "apt is free"
fi
grep -rhsE '^(deb|Components:|Suites:)' /etc/apt/sources.list /etc/apt/sources.list.d/ | grep -q universe \
  && pass "'universe' repository enabled" || fail "'universe' not enabled - run: sudo add-apt-repository universe"
UPG=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
[ "$UPG" -eq 0 ] && pass "System up to date" || warn "$UPG packages can be upgraded - run: sudo apt update && sudo apt full-upgrade"
for p in curl git; do
  command -v $p >/dev/null && pass "$p installed" || warn "$p not installed - run: sudo apt install $p"
done

section "Locale"
LOCALE_NOW=$(locale 2>/dev/null | awk -F= '/^LANG=/{print $2}')
[[ "$LOCALE_NOW" == *UTF-8* || "$LOCALE_NOW" == *utf8* ]] && pass "LANG=$LOCALE_NOW" || fail "LANG=${LOCALE_NOW:-unset} - ROS 2 needs a UTF-8 locale (Part 9.1)"

echo
echo "-----------------------------------------------------------------------"
echo "  $PASS passed, $WARNS warnings, $FAILS failed"
if [ "$FAILS" -eq 0 ]; then
  echo -e "  \033[1;32mThis CM4 is ready for ROS 2 Humble.\033[0m"
else
  echo -e "  \033[1;31mFix the FAIL items before installing ROS 2.\033[0m"
fi
echo "-----------------------------------------------------------------------"
echo
[ "$FAILS" -eq 0 ]
