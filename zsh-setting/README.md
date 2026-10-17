# Zsh Configuration

These examples target Debian/WSL with Oh My Zsh and Powerlevel10k. The [base setup](../setup-guide/Zsh%20-%20setup.md) installs the shell and plugins; the [further setup](../setup-guide/Zsh%20-%20Further%20Setup.md) installs mise and its tools.

## Startup responsibilities

| File | Loaded for | Contents |
| --- | --- | --- |
| [.zshenv](./.zshenv) | Every normal Zsh invocation | Private exports, base PATH, default Java, editor, and optional CUDA paths |
| [.zprofile](./.zprofile) | Login shells | Reuse or start an SSH agent |
| [zshrc.custom.zsh](./zshrc.custom.zsh) | Merge into interactive `~/.zshrc` | Theme, plugins, aliases, and mise activation |
