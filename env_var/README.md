# Environment Variables

Copy the `.env_var.template` file to `.env_var` at `$HOME` and fill in the values.

## Windows

For Windows, set persistent user environment variables by running:

```powershell
just export-env
```

## Debian / WSL with Zsh

Run these commands from the repository root:

```bash
cp env_var/.env_var.template "$HOME/.env_var"
sed -i 's/\r$//' "$HOME/.env_var"
chmod 600 "$HOME/.env_var"
code "$HOME/.env_var"
```

[Zsh environment example](../zsh-setting/.zshenv) will load this `.env_var` file, but you can manually add:

```zsh
if [[ -r "$HOME/.env_var" ]]; then
  source "$HOME/.env_var"
fi
```

Zsh loads this environment for `zsh -c`, `zsh -lc`, `zsh -ic`, and `zsh -ilc`.
