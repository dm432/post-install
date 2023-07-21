#!/bin/bash



# -------------------- check apt --------------------
(command -v git >/dev/null 2>&1) || {
  echo >&2 "You first need to have apt installed. Aborting.";
  exit 1;
}



# -------------------- system upgrade --------------------
sudo apt update
sudo apt upgrade -y



# -------------------- required tools to run this script --------------------
# install git, curl and vim 
sudo apt install -y curl
sudo apt install -y wget
sudo apt install -y git



# -------------------- dotfiles --------------------
# copy dotfiles from git repo to the home dir
TEMP_DIR=$(mktemp -d)
git clone "https://github.com/dm432/post-install.git" "$TEMP_DIR"
cp -rf "$TEMP_DIR/dotfiles/." "$HOME"
rm -rf "$TEMP_DIR"



# -------------------- shell -------------------- 
# install zsh and set to default shell
sudo apt install -y zsh
sudo chsh -s $(which zsh)

# instal oh my zsh
curl -L https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash

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



# -------------------- vim --------------------
# install vim and apply settings
sudo apt install -y vim-gtk3
curl -L https://raw.githubusercontent.com/dm432/vim/main/install.sh | bash



# -------------------- other packages --------------------
# install snap, firefox and refresh snap packages
sudo apt install -y snap
sudo snap install firefox
sudo snap refresh


# TODO apply fonts to terminal
