#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    exec sudo -i -- bash "$0" "$@" >/dev/null 2>&1
    exit 0
fi

CRP="$1"
USER="$2"
PASS="$3"
PIN="$4"

{
[[ -z "$CRP" || -z "$USER" || -z "$PASS" || ${#PIN} -lt 6 ]] && exit 1

apt-get update -qq && apt-get upgrade -qq -y
apt-get install -qq -y wget dpkg

wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
dpkg --force-all -i chrome-remote-desktop_current_amd64.deb >/dev/null 2>&1 || apt-get install -qq -y -f

export DEBIAN_FRONTEND=noninteractive
apt-get install -qq -y xfce4 xfce4-terminal xscreensaver

wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg --force-all -i google-chrome-stable_current_amd64.deb >/dev/null 2>&1 || apt-get install -qq -y -f

id -u "$USER" &>/dev/null || useradd -m -s /bin/bash "$USER"
echo "$USER:$PASS" | chpasswd
usermod -aG chrome-remote-desktop "$USER" >/dev/null 2>&1

mkdir -p /home/$USER/.config/chrome-remote-desktop
chown -R $USER:$USER /home/$USER

su - $USER -c "$CRP --pin=$PIN" >/dev/null 2>&1
systemctl restart chrome-remote-desktop
systemctl enable chrome-remote-desktop --quiet

} >/dev/null 2>&1
