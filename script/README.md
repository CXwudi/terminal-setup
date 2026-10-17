# Update Scripts

## Tool ownership

| Script | Responsibility |
| --- | --- |
| [ai-tools-update.ps1](./ai-tools-update.ps1) | Windows: Scoop, portable mise, mise-managed tools, direct uv tools, and Pi extensions |
| [ai-tools-update.sh](./ai-tools-update.sh) | Debian/WSL: mise, mise-managed tools, direct uv tools, and Pi extensions |
| [ai-tools-update.startup.ps1](./ai-tools-update.startup.ps1) | Windows launcher for Task Scheduler, logs, and duplicate-run control |

The updaters run from the user's home directory so a project's mise configuration does not select the tools being updated. mise-managed commands run through `mise exec`.

- `mise self-update -y` updates the portable mise installation.
- `mise upgrade` updates the runtimes and CLIs declared in the global configuration, including uv and `pypi:` tools.
- `mise exec -- uv tool upgrade --all` updates direct uv installations, currently MinerU if installed.
- `mise exec -- pi update --extensions` updates Pi extensions.
- The Windows script also runs `scoop update`, `scoop update '*'`, and `scoop cleanup '*'`.

The scripts stop on a failed step. pnpm and Bun serve project dependencies here; there is no global-package update step. Package-managed mise installations should be updated by their package manager instead of these scripts' portable self-update step.

## Install on Windows

Run from the repository root after completing the selected Windows setup. Choose the same bin directory used for portable mise:

```powershell
# C drive layout:
$scriptBin = Join-Path $env:USERPROFILE '.local\bin'
# D drive layout: replace the assignment above with $scriptBin = 'D:\local\bin'

New-Item -ItemType Directory -Force -Path $scriptBin | Out-Null
Copy-Item -LiteralPath 'script/ai-tools-update.ps1','script/ai-tools-update.startup.ps1' -Destination $scriptBin
```

That directory must be in persistent user PATH. Run `ai-tools-update.ps1` for a manual update. It requires Scoop and the global mise configuration from the [Windows guide](../setup-guide/PowerShell%20-%20Further%20Setup.md).

## Configure Task Scheduler

Create a task that runs as your normal Windows user. For a startup-style daily update, use an **At log on** trigger and enable **Run only when user is logged on**.

Set the action to **Start a program**:

- Program: the full path to PowerShell 7, usually `C:\Program Files\PowerShell\7\pwsh.exe`.
- Arguments: use the resolved line printed below.
- Start in: your user's home directory.

```powershell
'-NoLogo -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $scriptBin 'ai-tools-update.startup.ps1')
```

The launcher finds `ai-tools-update.ps1` through PATH. Its `$UpdaterPath` setting can specify a full path if needed. Logs and run state are stored under `%LOCALAPPDATA%\ai-tools-update`. The launcher's existing retention and duplicate-run settings remain configurable near the top of the script.

Fully restart the terminal and applications after changing persistent environment variables, then start the task manually once to verify the actual installation. Starting it runs real updates.

## Install on Debian / WSL

Run from the repository root:

```bash
mkdir -p "$HOME/.local/bin"
install -m 755 script/ai-tools-update.sh "$HOME/.local/bin/ai-tools-update.sh"
```

Run `ai-tools-update.sh` for a manual update. It uses `~/.local/bin/mise` from the official installer, with a PATH lookup fallback for a custom installation. This repository does not create a Linux scheduled task.

## Remove US English

[remove-us-english.ps1](./remove-us-english.ps1) removes the English (US) layout sometimes added by Apex Legends while preserving the other language layouts.
