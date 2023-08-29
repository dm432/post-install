#!/bin/bash

# -------------------- check apt --------------------
(command -v git >/dev/null 2>&1) || {
  echo >&2 "You first need to have apt installed. Aborting."
  exit 1
}

# -------------------- ask user what to install --------------------
ask_user() {
  if [ "$INSTALL_EVERYTHING" -eq 1 ]; then
    while true; do
      read -r -p "$1 [Y/n]: " yn
      case $yn in
      [Yy]* | "") return 0 ;;
      [Nn]*) return 1 ;;
      *) ;;
      esac
    done
  else
    return 0
  fi
}

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

# -------------------- make temp directory --------------------
TEMP_DIR=$(mktemp -d)

# -------------------- system upgrade --------------------
sudo apt update
sudo apt upgrade -y

# Install snap and refresh packages
sudo apt install -y snap
sudo snap refresh

# -------------------- required tools to run this script --------------------
sudo apt install -y curl
sudo apt install -y wget
sudo apt install -y git
sudo apt install -y ca-certificates
sudo apt install -y gnupg

# -------------------- repositories  --------------------
# docker
if [ "$INSTALL_DOCKER" -eq 0 ]; then
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
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
fi

# update package index
sudo apt-get update

# -------------------- dotfiles --------------------
# copy dotfiles from git repo to the home dir
git clone "https://github.com/dm432/post-install.git" "$TEMP_DIR"

if [ "$INSTALL_ZSH" -eq 0 ]; then
  cp -f "$TEMP_DIR/dotfiles/.p10k.zsh" "$HOME"
  cp -f "$TEMP_DIR/dotfiles/.zshrc" "$HOME"
fi

# -------------------- shell --------------------
if [ "$INSTALL_ZSH" -eq 0 ]; then
  # install zsh and set to default shell
  sudo apt install -y zsh
  sudo chsh -s $(which zsh)

  # install oh my zsh
  curl -L https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash

  # install zsh plugins
  git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting

  # install powerlevel10k fonts
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
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
  echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
fi

if [ "$INSTALL_THE_FUCK" -eq 0 ]; then
  sudo apt install thefuck
  echo "eval $(thefuck --alias)" | tee -a ~/.zshrc
  source ~/.zshrc
fi

# -------------------- vim --------------------
# install vim and apply settings
if [ "$APPLY_VIM_SETTINGS" -eq 0 ]; then
  sudo apt install -y vim-gtk3
  curl -L https://raw.githubusercontent.com/dm432/vim/main/install.sh | bash
fi

# -------------------- other packages --------------------
# docker
if [ "$INSTALL_DOCKER" -eq 0 ]; then
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# minikube
if [ "$INSTALL_MINIKUBE" -eq 0 ]; then
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 --output-dir "$TEMP_DIR"
  sudo install "$TEMP_DIR/minikube-linux-amd64" /usr/local/bin/minikube
fi

# kubectl
if [ "$INSTALL_KUBECTL" -eq 0 ]; then
  sudo apt-get install -y kubectl
fi

# k9s
if [ "$INSTALL_K9S" -eq 0 ]; then
  sudo curl -sL https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz | sudo tar xzf - -C /usr/local/bin k9s
fi

#htop
if [ "$INSTALL_HTOP" -eq 0 ]; then
  sudo apt install htop
fi

# vivaldi browser
if [ "$INSTALL_VIVALDI" -eq 0 ]; then
  curl -L https://downloads.vivaldi.com/snapshot/install-vivaldi.sh -o "$TEMP_DIR/install-vivaldi.sh"
  bash "$TEMP_DIR/install-vivaldi.sh" --no-launch
fi

# -------------------- remove temp directory --------------------
rm -rf "$TEMP_DIR"

# -------------------- print some information for the user --------------------
LIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'

echo -e "${LIGHT_GREEN}All set!"

if [ "$INSTALL_ZSH" -eq 0 ]; then
  echo -e "${RED}Make sure to apply the MesloLGS NF font to your terminal. Otherwise powerlevel10k will not be displayed properly!"
  echo -e "${RED}In order to make zsh your default shell, you need to log out and back in again!"
fi
