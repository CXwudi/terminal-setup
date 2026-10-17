# Further Zsh Setup: mise and Development Tools

Complete the [base Zsh setup](./Zsh%20-%20setup.md) first. The commands below target Debian/WSL x64 and run from the repository root.

## 1. Install additional system packages

```bash
sudo apt update
sudo apt install -y gh bubblewrap
```

## 2. Install mise

Install the official release binary:

```bash
curl -fsSL https://mise.run | sh
"$HOME/.local/bin/mise" --version
source "$HOME/.zshenv"
```

The [startup examples](../zsh-setting/) already provide shims through `.zshenv` and interactive activation through `.zshrc`. [mise installation](https://mise.jdx.dev/installing-mise.html)

## 3. Copy the global configuration and install tools

This guide uses the default global config directory, `~/.config/mise`. If you set `MISE_CONFIG_DIR` or `XDG_CONFIG_HOME`, use the corresponding directory instead.

```bash
mkdir -p "$HOME/.config/mise"
cp setup-guide/mise-configs/config.linux.toml "$HOME/.config/mise/config.toml"

# Work outside project configs.
(
  cd "$HOME"
  "$HOME/.local/bin/mise" install
)
```

All declarations come from the [Linux configuration backup](./mise-configs/config.linux.toml). Review that file to choose which tools to install. mise manages the declared CLIs, including `pypi:` tools installed through uv.

uv chooses compatible Python interpreters for ordinary CLI installs. streamrip keeps its explicit Python 3.13 requirement. Node remains declared because the `npm:` CLIs need it. See [tool ownership](./README.md#tool-ownership).

Java follows the latest ordinary Liberica LTS. The default `JAVA_HOME` in `.zshenv` uses the stable global JDK link, while interactive mise activation and `mise exec` can select a project's JDK.

Optional completion generation, after mise is available:

```bash
sudo mkdir -p /usr/local/share/zsh/site-functions
mise completion zsh | sudo tee /usr/local/share/zsh/site-functions/_mise >/dev/null
```

## 4. Optional: MinerU

MinerU stays directly managed by uv and uses Python 3.12:

```zsh
mise exec -- uv tool install 'mineru[all]' --python 3.12
```

Check the [MinerU installation guide](https://github.com/opendatalab/MinerU#installation) for the chosen backend's hardware, CUDA, and dependency requirements. The optional CUDA paths in `.zshenv` support an existing toolkit; they do not install one.

uv can also install interpreters explicitly when a project requires one:

```zsh
mise exec -- uv python install 3.12
```

## 5. pnpm and Bun environment

The shared `.zshenv` exports `PNPM_HOME` to locate pnpm data for interactive and non-interactive commands. Bun uses its own default data directories, with directory overrides needed only for custom locations. mise supplies both executables.

Check the configured pnpm data root:

```zsh
printenv PNPM_HOME
```

The shared PATH array already includes the pnpm/Bun global command directories after mise shims. This keeps commands installed with `pnpm add -g` or `bun add -g` available while mise continues to select the executable versions. Bun directory override variables remain unset. See the [Zsh environment notes](../zsh-setting/README.md#environment-behavior).

## 6. Verify and configure updates

Open a new Zsh terminal, then check:

```zsh
mise ls --current
command -v mise uv node pnpm bun java ast-outline ninja
uv --version
node --version
pnpm --version
java -version
"$JAVA_HOME/bin/java" -version
uv tool list
```

If MinerU was installed, `uv tool list` should list it. mise-managed `pypi:` tools are stored separately.

Check both non-interactive modes:

```bash
zsh -c 'command -v uv node pnpm java; test -x "$JAVA_HOME/bin/java"'
zsh -lc 'command -v uv node pnpm java; test -x "$JAVA_HOME/bin/java"'
```

Install the [update script](../script/) for maintenance. It updates tools from your home directory according to their owner.
