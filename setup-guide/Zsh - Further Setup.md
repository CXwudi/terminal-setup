# Further Setup - uv, mise, node, pnpm, bun, AI CLIs

<!-- markdownlint-disable MD013 -->

Website:

- [Scoop](https://github.com/ScoopInstaller/Install) - Windows package manager
- [uv (Astral)](https://docs.astral.sh/uv/getting-started/installation/) -
  Python package manager
- [mise](https://mise.jdx.dev/getting-started.html) - version manager
- [pnpm](https://pnpm.io/installation) - Node package manager
- [Bun](https://bun.sh/docs/runtime/bunfig) - JavaScript runtime & package
  manager
- [SDKMAN](https://sdkman.io/install) - JVM version manager

AI CLIs:

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- [OpenAI Codex](https://github.com/openai/codex)
- [Pi Coding Agent](https://github.com/badlogic/pi-mono)

## 1. Assumptions

- You already finished the first setup (oh-my-zsh + powerlevel10k, zsh is
  default, curl/git/zsh installed).
- The commands below target Debian/WSL with zsh.

## 2. Install Further Packages from apt

```bash
sudo apt install gh bubblewrap -y
```

## 2. Install uv

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.zshrc
uv --version
# optional: manage Python versions with uv
# uv python install 3.12
```

## 3. Install tools via uv

The tool `mineru[all]` requires high-end GPU and complicated CUDA setup, always
best to check latest guide

```bash
uv tool install 'mineru[all]' --python 3.12
```

## 4. Install and Activate mise

```bash
# install mise if missing
if ! command -v mise >/dev/null 2>&1; then
  curl -fsSL https://mise.run | sh
fi

echo 'eval "$(mise activate zsh --shims)"' >> ~/.zprofile # this sets up non-interactive sessions
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc    # this sets up interactive sessions

# completions (optional)
mise completion zsh | sudo tee /usr/local/share/zsh/site-functions/_mise > /dev/null
```

## 5. Install Tools via mise

take [`config.linux.toml`](mise-configs/config.linux.toml) and copied it into `~/.config/mise/config.toml`

```bash
# install tools
mise install

# check versions
node -v
pnpm -v
```

## 6. Set PNPM_HOME and PATH

```bash
# set PNPM_HOME to an XDG-compliant location
export PNPM_HOME="$HOME/.local/share/pnpm"
mkdir -p "$PNPM_HOME"

# create PNPM_HOME and add PNPM_HOME/bin to PATH if missing
grep -q 'PNPM_HOME' ~/.zshrc || {
  echo '# PNPM' >> ~/.zshrc
  echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> ~/.zshrc
  echo 'export PATH="$PNPM_HOME/bin:$PATH"' >> ~/.zshrc
}

# update shims
mise reshim
```

## 7. Install Global Packages via pnpm

```bash
# so far empty, we use mise for now
```

## 8. Set BUN_INSTALL_BIN and PATH

```bash
# set BUN_INSTALL_BIN to default location
export BUN_INSTALL_BIN="$HOME/.bun/bin"
mkdir -p "$BUN_INSTALL_BIN"

# add BUN_INSTALL_BIN to PATH if missing
grep -q 'BUN_INSTALL_BIN' ~/.zshrc || {
  echo '# Bun' >> ~/.zshrc
  echo 'export BUN_INSTALL_BIN="$HOME/.bun/bin"' >> ~/.zshrc
  echo 'export PATH="$BUN_INSTALL_BIN:$PATH"' >> ~/.zshrc
}

# update shims
mise reshim
```

## 9. Setup SDKMAN (Zsh)

```bash
# Install SDKMAN!
curl -s "https://get.sdkman.io" | bash

# Ensure zsh loads SDKMAN (idempotent)
grep -q 'sdkman-init.sh' ~/.zshrc || {
  echo 'export SDKMAN_DIR="$HOME/.sdkman"' >> ~/.zshrc
  echo '[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"' >> ~/.zshrc
}

# Verify
sdk version

# Optional: install Java or Liberica NIK
# sdk list java
# sdk install java <identifier>
# sdk list nik
# sdk install nik <version>
```
