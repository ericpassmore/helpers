sudo apt update && sudo apt upgrade -y
sudo vi /ect/wsl.conf
cd /home
cp /mnt/c/Users/EricPassmore/env personal.env
source personal.env 
mkdir repos
cd repos/
git clone https://${GIT_OP_PAT}@dev.azure.com/OrderPortLLC/main-system/_git/main-system
code main-system/
git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"
git config --global user.name "Eric Passmore"
git config --global user.email "eric.passmore@gmail.com"
mkdir ~/download-software
cd ~/download-software
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/UbuntuMono.zip
sudo apt install unzip
unzip UbuntuMono.zip -d ~/.local/share/fonts
mkdir /home/eric/.local
mkdir /home/eric/.local/share
mkdir /home/eric/.local/share/fonts
unzip UbuntuMono.zip -d ~/.local/share/fonts
fc-cache -fv
curl -sS https://starship.rs/install.sh | sh
echo $SHELL
eval "$(starship init bash)"
mkdir -p ~/.config
cd ../
vi ~/.bashrc
gpg --list-secret-keys --keyid-format=long
git config --global --list
git config --global commit.gpgsign true
git config --global tag.gpgsign true
gpg --import /mnt/c/Users/EricPassmore/Documents/code.public.signkey.2026.key 
gpg --import /mnt/c/Users/EricPassmore/Documents/root.secret.2026.gpg
git config --global --list
gpg --list-keys --keyid-format=long 
git config --global user.signingkey 227EF046BFDB298A!
git config --global --list
mkdir ~/.gnupg
chmod 700 ~/.gnupg
printf "pinentry-program /usr/bin/pinentry-curses\n" > ~/.gnupg/gpg-agent.conf
gpgconf --launch gpg-agent
echo 'export GPG_TTY=$(tty)' >> ~/.bashrc
source ~/.bashrc
echo test | gpg --clearsign
