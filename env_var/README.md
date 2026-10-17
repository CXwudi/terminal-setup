# Environment Variables

Copy the `.env_var.template` file to `.env_var` at `$HOME` and fill in the values.

## Windows

After installing mise, run from anywhere in this repository to import the file at `$HOME` into persistent user environment variables:

```powershell
mise run //env_var:export-env "$HOME/.env_var"
```

To use `env_var/.env_var` instead, run `mise run //env_var:export-env` without a file argument. Relative file paths are resolved from `env_var/`. Inside that directory, use `mise run :export-env [path/to/file]`. Run `mise tasks --all` to list all monorepo tasks. See [mise task arguments](https://mise.jdx.dev/tasks/task-arguments.html).

Restart terminals and applications after importing to pick up the changes.

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
