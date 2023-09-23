#!/bin/bash

LIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'
WHITE='\033[1;37m'
CYAN='\033[0;36m'

check_apt_get_installed() {
  command -v apt-get &>/dev/null
}

create_tmp_dir() {
  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TEMP_DIR"' EXIT
}

perform_system_upgrade() {
  echo "Performing system upgrade..." > /dev/tty
  sudo apt-get update
  sudo apt-get upgrade -y
  sudo apt-get dist-upgrade -y
  sudo apt-get autoremove -y
  sudo apt-get clean
}

install_required_tools() {
  echo "Installing required tools (curl, wget, git, ca-certificates and gnupg)..." > /dev/tty
  sudo apt-get install -y curl wget git ca-certificates gnupg
}

add_repositories() {
  # docker
  if [ "$INSTALL_DOCKER" -eq 0 ]; then
    echo "Adding Docker repository..." > /dev/tty
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  fi

  # google cloud
  if [ "$INSTALL_MINIKUBE" -eq 0 ]; then
    echo "Adding Google Cloud repository (for Kubernetes)..." > /dev/tty
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  fi

  echo "Performing system update..." > /dev/tty
  sudo apt-get update
}

clone_repo() {
  echo "Cloning post-install git repo..." > /dev/tty
  git clone "https://github.com/dm432/post-install.git" "$TEMP_DIR"
}

ask_user() {
  if [ "$INSTALL_EVERYTHING" -eq 1 ]; then
    while true; do
      echo -n "$1 [Y/n]: " > /dev/tty
      read -r USER_INPUT < /dev/tty
      case $USER_INPUT in
      [Yy]* | "") return 0 ;;
      [Nn]*) return 1 ;;
      *) ;;
      esac
    done
  else
    return 0
  fi
}

ask_what_to_install() {
  INSTALL_EVERYTHING=1
  ask_user "Install everything? (No for a custom install)"
  INSTALL_EVERYTHING=$?

  ask_user "Install Docker?"
  INSTALL_DOCKER=$?

  ask_user "Install Minikube?"
  INSTALL_MINIKUBE=$?

  if [ "$INSTALL_MINIKUBE" -eq 0 ]; then
    ask_user "Install Kubectl?"
    INSTALL_KUBECTL=$?
  else
    INSTALL_KUBECTL=1
  fi

  if [ "$INSTALL_MINIKUBE" -eq 0 ]; then
    ask_user "Install K9s?"
    INSTALL_K9S=$?
  else
    INSTALL_K9S=1
  fi

  ask_user "Apply my Vim Settings?"
  APPLY_VIM_SETTINGS=$?

  ask_user "Install Oh My Zsh with the Powerlevel10k theme and set as default shell?"
  INSTALL_ZSH=$?

  ask_user "Install The Fuck?"
  INSTALL_THE_FUCK=$?

  ask_user "Install Htop?"
  INSTALL_HTOP=$?

  ask_user "Install Vivaldi browser?"
  INSTALL_VIVALDI=$?
}

install_zsh() {
  # copy zsh dotfiles
  echo "Copying Zsh config files..." > /dev/tty
  cp -f "$TEMP_DIR/dotfiles/.p10k.zsh" "$HOME"
  cp -f "$TEMP_DIR/dotfiles/.zshrc" "$HOME"

  # install zsh and set to default shell
  echo "Installing Zsh..." > /dev/tty
  sudo apt-get install -y zsh
  sudo chsh -s $(which zsh)

  # install oh my zsh
  echo "Installing Oh My Zsh..." > /dev/tty
  curl -L https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash

  # install zsh plugins
  echo "Installing Zsh plugins..." > /dev/tty
  git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting

  # install powerlevel10k fonts
  echo "Installing Powerlevel10k fonts..." > /dev/tty
  POWERLEVEL10K_FONT_URLS=(
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
  )
  FONT_INSTALL_DIR="/usr/share/fonts/truetype/custom"
  if [ ! -d "$FONT_INSTALL_DIR" ]; then
    sudo mkdir -p "$FONT_INSTALL_DIR"
  fi
  for url in "${POWERLEVEL10K_FONT_URLS[@]}"; do
    sudo wget "$url" -P "$FONT_INSTALL_DIR"
  done
  sudo fc-cache -f -v

  # install powerlevel10k
  echo "Installing Powerlevel10k..." > /dev/tty
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
  echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
}

print_zsh_install_information() {
  echo -e "${RED}Make sure to apply the MesloLGS NF font to your terminal. Otherwise powerlevel10k will not be displayed properly!${WHITE}" > /dev/tty
  echo -e "${RED}In order to make zsh your default shell, you need to log out and back in again!${WHITE}" > /dev/tty
}

apply_vim_settings() {
  echo "Applying Vim settings..." > /dev/tty
  sudo apt-get install -y vim-gtk3
  curl -L https://raw.githubusercontent.com/dm432/vim/main/install.sh | bash
}

install_selected_tools() {
  if [ "$INSTALL_THE_FUCK" -eq 0 ]; then
    echo "Installing The Fuck..." > /dev/tty
    sudo apt-get install thefuck
    echo "eval \$(thefuck --alias)" >>~/.zshrc
    source ~/.zshrc
  fi

  if [ "$INSTALL_DOCKER" -eq 0 ]; then
    echo "Installing Docker..." > /dev/tty
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi

  if [ "$INSTALL_MINIKUBE" -eq 0 ]; then
    echo "Installing Minikube..." > /dev/tty
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 --output-dir "$TEMP_DIR"
    sudo install "$TEMP_DIR/minikube-linux-amd64" /usr/local/bin/minikube
  fi

  if [ "$INSTALL_KUBECTL" -eq 0 ]; then
    echo "Installing Kubectl..." > /dev/tty
    sudo apt-get install -y kubectl
  fi

  if [ "$INSTALL_K9S" -eq 0 ]; then
    echo "Installing K9s..." > /dev/tty
    sudo curl -sL https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz | sudo tar xzf - -C /usr/local/bin k9s
  fi

  if [ "$INSTALL_HTOP" -eq 0 ]; then
    echo "Installing Htop..." > /dev/tty
    sudo apt-get install htop
  fi

  if [ "$INSTALL_VIVALDI" -eq 0 ]; then
    echo "Installing Vivaldi..." > /dev/tty
    curl -L https://downloads.vivaldi.com/snapshot/install-vivaldi.sh -o "$TEMP_DIR/install-vivaldi.sh"
    bash "$TEMP_DIR/install-vivaldi.sh" --no-launch
  fi
}

main() {
  exec > "install.log" 2>&1
  echo -e "The output of this script will be logged to ${CYAN}$(pwd)/install.log${WHITE}" > /dev/tty

  if ! check_apt_get_installed; then
    echo >&2 "Error: apt-get is not installed. Aborting."
    exit 1
  fi

  create_tmp_dir
  ask_what_to_install
  perform_system_upgrade
  install_required_tools
  add_repositories
  clone_repo

  if [ "$INSTALL_ZSH" -eq 0 ]; then
    install_zsh
  fi

  if [ "$APPLY_VIM_SETTINGS" -eq 0 ]; then
    apply_vim_settings
  fi

  install_selected_tools

  echo -e "${LIGHT_GREEN}All set!${WHITE}" > /dev/tty
  if [ "$INSTALL_ZSH" -eq 0 ]; then
    print_zsh_install_information
  fi
}

main
