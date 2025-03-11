#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    exec sudo -i -- bash "$0" "$@"
    exit 1
fi
CRP="$1"
USER="$2"
PASS="$3"
PIN="$4"

validate_inputs() {
  [[ -z "$CRP" || -z "$USER" || -z "$PASS" || ${#PIN} -lt 6 ]] && {
    echo -e "\033[91mUsage:\033[0m"
    echo "bash <(curl -s https://...) \\"
    echo "    AUTH_CODE USERNAME PASSWORD PIN"
    echo -e "\n\033[93mExample:\033[0m"
    echo "bash <(curl -s https://gist.gith...) \\"
    echo "    ABCD-EFGH myuser MyPass123! 123456"
    exit 1
  }
}
install_deps() {
  echo -e "\n\033[94mUpdating System...\033[0m"
  apt update -y
  apt upgrade -y
  apt install -y wget dpkg gnupg2
}
install_crd() {
  echo -e "\n\033[94mInstalling Chrome Remote Desktop...\033[0m"
  wget -q --show-progress https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
  dpkg -i chrome-remote-desktop_current_amd64.deb || apt install --assume-yes --fix-broken
}
install_xfce() {
  echo -e "\n\033[94mSetting Up XFCE Desktop...\033[0m"
  export DEBIAN_FRONTEND=noninteractive
  apt install -y xfce4 xfce4-terminal xfce4-goodies
  apt purge -y gnome-terminal
  apt install -y xscreensaver
  echo "exec /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session
}
install_chrome() {
  echo -e "\n\033[94mInstalling Google Chrome...\033[0m"
  wget -q --show-progress https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  dpkg -i google-chrome-stable_current_amd64.deb || apt install --assume-yes --fix-broken
}
setup_user() {
  echo -e "\n\033[94mCreating User: $USER...\033[0m"
  if id "$USER" &>/dev/null; then
    echo "User $USER already exists! Changing password..."
  else
    useradd -m -s /bin/bash "$USER"
  fi
  echo "$USER:$PASS" | chpasswd
  usermod -aG sudo,chrome-remote-desktop "$USER"
  mkdir -p /home/$USER/.config/chrome-remote-desktop
  chown -R $USER:$USER /home/$USER
}

start_services() {
  echo -e "\n\033[94mStarting RDP Service...\033[0m"
  su - $USER -c "$CRP --pin=$PIN"
  systemctl restart chrome-remote-desktop
  systemctl enable chrome-remote-desktop
}

main() {
  validate_inputs
  install_deps
  install_crd
  install_xfce
  install_chrome
  setup_user
  start_services
  
  echo -e "\n\033[92mSetup Completed Successfully!\033[0m"
  echo -e "Connect using: \033[4mhttps://remotedesktop.google.com/access\033[0m"
}
main
