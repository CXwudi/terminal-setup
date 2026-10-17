# Set Up Zsh, Oh My Zsh, and Powerlevel10k

These commands target Debian/WSL. Run them from the repository root.

## 1. Install a terminal font

Install [MesloLGS NF using Powerlevel10k's font instructions](https://github.com/romkatv/powerlevel10k#manual-font-installation). Configure the font in Windows Terminal, VS Code, or the IDE terminal that displays your WSL session.

## 2. Install the shell and base packages

```bash
sudo apt update
sudo apt install -y ca-certificates curl git zsh openssh-client ripgrep fzf rsync lsd tmux unzip

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
```

Install the theme and additional plugins:

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/Pilaton/OhMyZsh-full-autoupdate.git "$HOME/.oh-my-zsh/custom/plugins/ohmyzsh-full-autoupdate"
```

These paths use Oh My Zsh's default custom directory. Adjust them if you configured `ZSH_CUSTOM` elsewhere.

## 3. Configure Zsh startup files

Follow the [Zsh configuration guide](../zsh-setting/) to copy `.zshenv` and `.zprofile`, then merge the two sections of `zshrc.custom.zsh` into the generated `~/.zshrc`.

The shared environment belongs in `.zshenv`, login initialization in `.zprofile`, and interactive configuration in `.zshrc`. The custom fragment includes the Powerlevel10k theme, plugin list, `lsd` alias, `NOMATCH` preference, and mise activation. The activation guard allows this base setup to run before mise is installed.

For private exports, follow the [environment-variable guide](../env_var/). The editor defaults to `code --wait`; adjust `EDITOR` in `.zshenv` if you use another editor.

## 4. Start Zsh and configure the prompt

Set Zsh as the default shell:

```bash
chsh -s /usr/bin/zsh
```

Open a new terminal. Run the Powerlevel10k wizard and choose the desired appearance:

```zsh
p10k configure
```

To reproduce my prompt setup, enter the following responses in order, one at each wizard prompt:

```text
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

The prompts can vary with the terminal, font, and Powerlevel10k version. Follow the questions displayed by your wizard if they differ from this sequence.

Keep the wizard's generated instant-prompt block near the top of `.zshrc`, and keep one source of `~/.p10k.zsh` after Oh My Zsh initialization.

Continue with [Zsh - Further Setup](./Zsh%20-%20Further%20Setup.md).
