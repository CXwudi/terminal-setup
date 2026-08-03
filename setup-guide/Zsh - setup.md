# How to setup oh my zsh + powerlevel10k

<!-- markdownlint-disable MD013 -->

website:

1. [oh my zsh](https://github.com/ohmyzsh/ohmyzsh/wiki)
2. [powerlevel10k](https://github.com/romkatv/powerlevel10k#getting-started)

## 1. Install Meslo Nerd Font

Some common terminals:

- Windows Terminal for WSL
- Ubuntu default terminal
- VSCode terminal
- Intellij terminal

## 2. Install Oh My Zsh and Plugins

```bash
sudo apt update
sudo apt install curl git zsh python3 ripgrep tree fzf rsync lsd tmux -y
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/Pilaton/OhMyZsh-full-autoupdate ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate
```

## 3. (Optional) Install Homebrew

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

and follow homebrew instruction in console to finish setting up homebrew.

you might want to do `cat .zprofile >> .zshrc` so that in-GUI terminal can get
brew

```bash
brew install python3
```

## 4. Configure Theme and Plugins

```bash
# Set ZSH_THEME in ~/.zshrc
sed -i.bak 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# Add plugins to ~/.zshrc
plugins='(git z dirhistory fzf aliases docker docker-compose common-aliases zsh-syntax-highlighting zsh-autosuggestions ohmyzsh-full-autoupdate)'
sed -i.bak "s/plugins=(.*)/plugins=${plugins}/" ~/.zshrc

# Add bin to PATH to ~/.zprofile
echo 'export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"' >> ~/.zprofile

# Add ssh-agent setup to ~/.zprofile
cat <<'EOF' >> ~/.zprofile
if [ -z "$SSH_AUTH_SOCK" ]; then
  # Check for a currently running instance of the agent
  RUNNING_AGENT="`ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]'`"
  if [ "$RUNNING_AGENT" = "0" ]; then
    # Launch a new instance of the agent
    ssh-agent -s &> "$HOME/.ssh/ssh-agent"
  fi
  eval `cat "$HOME/.ssh/ssh-agent"` 2>&1 >/dev/null
fi
EOF


# Add alias
echo "alias ls='lsd'" >> ~/.zshrc

# Add editor
echo 'export EDITOR="code --wait"' >> ~/.zshrc

# Add Bash Compatible
echo 'unsetopt NOMATCH' >> ~/.zshrc

# Change default shell to zsh
chsh -s /usr/bin/zsh
```

## 5. Run Powerlevel10k Configuration Wizard

Use this quick configuration to setup the default style shown in the
[github repo](https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/configuration-wizard.gif):

```shall
p10k configure
y
y
y
1
y
3
1
2
1
3
1
2
2
1
2
2
2
1
y
1
y
```
