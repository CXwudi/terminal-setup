# Env Var

Copy the `.env_var.template` file to `.env_var` at `$HOME` and fill in the values.

For Windows, set persistent user environment variables by running:

```powershell
just export-env
```

For Linux, copy it to `$HOME` and normalize line endings:

```bash
sed -i 's/\r$//' "$HOME/.env_var"
```

Then in `~/.bashrc` or `~/.zshrc`, add:

```bash
if [ -f "$HOME/.env_var" ]; then
  . "$HOME/.env_var"
fi
```

If you keep editing `.env_var` from Windows and see `command not found: ^M`,
use this CRLF-safe version in `~/.zshrc` instead:

```zsh
if [ -f "$HOME/.env_var" ]; then
  source <(sed 's/\r$//' "$HOME/.env_var")
fi
```
