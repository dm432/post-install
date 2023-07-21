#!/bin/bash



# -------------------- check apt --------------------
(command -v git >/dev/null 2>&1) || {
  echo >&2 "You first need to have apt installed. Aborting.";
  exit 1;
}



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
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# google cloud
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# update package index
sudo apt-get update



# -------------------- dotfiles --------------------
# copy dotfiles from git repo to the home dir
git clone "https://github.com/dm432/post-install.git" "$TEMP_DIR"
cp -rf "$TEMP_DIR/dotfiles/." "$HOME"



# -------------------- shell -------------------- 
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



# -------------------- vim --------------------
# install vim and apply settings
sudo apt install -y vim-gtk3
curl -L https://raw.githubusercontent.com/dm432/vim/main/install.sh | bash



# -------------------- other packages --------------------
# docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 --output-dir "$TEMP_DIR"
sudo install "$TEMP_DIR/minikube-linux-amd64" /usr/local/bin/minikube

# kubectl
sudo apt-get install -y kubectl

# k9s
sudo curl -sL https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz | sudo tar xzf - -C /usr/local/bin k9s

# firefox 
sudo snap install firefox



# -------------------- remove temp directory --------------------
rm -rf "$TEMP_DIR"



# -------------------- print some information for the user --------------------
echo "All set! Make sure to apply the MesloLGS NF font to your terminal. Otherwise powerlevel10k will not be displayed properly!"
echo "In order to make zsh your default shell, you need to log out and back in again!"
