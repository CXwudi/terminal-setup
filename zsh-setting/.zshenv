# Shared environment for interactive and non-interactive Zsh processes.
if [[ -r "$HOME/.env_var" ]]; then
  source "$HOME/.env_var"
fi

# Preserve the first occurrence of each command directory in nested shells.
typeset -U path PATH
export PNPM_HOME="${PNPM_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/pnpm}"
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"
  "$PNPM_HOME/bin"
  "$HOME/.bun/bin"
  /usr/local/bin
  $path
)

# Preserve a JDK selected by the parent process; otherwise use the global JDK.
export JAVA_HOME="${JAVA_HOME:-${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/installs/java/global}"
export EDITOR="${EDITOR:-code --wait}"

# Optional CUDA support: only add toolkit directories that already exist.
if [[ -d /usr/local/cuda/bin ]]; then
  path=(/usr/local/cuda/bin $path)
fi
if [[ -d /usr/local/cuda/lib64 && ":${LD_LIBRARY_PATH:-}:" != *:/usr/local/cuda/lib64:* ]]; then
  export LD_LIBRARY_PATH="/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi
export PATH
