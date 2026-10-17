# Terminal Setup

My personal terminal configuration for Windows, PowerShell, and Zsh on WSL, shared as a reference for building a similar development environment. Each folder covers a standalone aspect of the setup.

Feel free to review and adapt them before use.

## Contents

- [Setup guides](./setup-guide/) — The main Env Setup. PowerShell, Zsh, package managers, development tools, AI Agents, etc.
- [Environment variables](./env_var/) — Cross-platform environment-variable setup
- [Zsh configuration](./zsh-setting/) — Shared environment, login initialization, and interactive configuration examples.
- [Windows Terminal and PowerShell configuration](./wt-setting/) — PowerShell profile and backup/restore helpers
- [Update scripts](./script/) — One-shot script for updating all package managers and their installed tools, plus a Windows Task Scheduler guide for automatic updates

## Tasks

The root [mise.toml](./mise.toml) enables [mise monorepo mode](https://mise.jdx.dev/tasks/monorepo.html) and registers `env_var/` and `wt-setting/` as projects. Their helper tasks are defined in each folder's `mise.toml` and can be called by `//folder:task` from anywhere in this repository.

With mise installed, run `mise trust` once from the repository root to enable the configuration. Then list all repository tasks with `mise tasks --all` or `mise run`. The Windows tasks include:

```powershell
mise run //env_var:export-env "$HOME/.env_var"
mise run //wt-setting:backup
mise run //wt-setting:restore
```

Run the command for the operation you need. See each folder's README for file paths and individual backup/restore tasks.
