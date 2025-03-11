#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    exec sudo -i -- bash "$0" "$@"
    exit 1
fi

CRP="$1"
USER="$2"
PASS="$3"
PIN="$4"

# اعتبارسنجی ورودی‌ها
[[ -z "$CRP" ]] && { echo "Error: CRP missing"; exit 1; }
[[ -z "$USER" ]] && { echo "Error: USER missing"; exit 1; }
[[ -z "$PASS" ]] && { echo "Error: PASS missing"; exit 1; }
[[ ${#PIN} -lt 6 ]] && { echo "Error: Invalid PIN"; exit 1; }

# مراحل نصب
apt-get update -y
apt-get install -y wget

wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
dpkg -i chrome-remote-desktop_current_amd64.deb || apt-get install -f -y

apt-get install -y xfce4 xfce4-terminal

useradd -m -s /bin/bash "$USER" 2>/dev/null || true
echo "$USER:$PASS" | chpasswd
usermod -aG chrome-remote-desktop "$USER"

su - $USER -c "$CRP --pin=$PIN"
systemctl restart chrome-remote-desktop
