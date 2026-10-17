# Further PowerShell Setup: C Drive

Use this guide for the default Windows user directories. Complete [PowerShell - Setup](./PowerShell%20-%20Setup.md) first.

Run the steps in order in one PowerShell 7 session, starting from the repository root. The [Windows configuration backup](./mise-configs/config.windows.toml) supplies every mise tool declaration.

## 1. Install Scoop and system CLIs

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
scoop install git
scoop bucket add extras
scoop install yq ast-grep ripgrep lsd fzf gh psmux
```

Scoop owns these system CLIs. The repository's helper tasks run directly through mise, installed in step 3.

## 2. Define the default directories

Keep the following variables in the current session for the remaining steps:

```powershell
$repoRoot = (Get-Location).Path
$toolBinDir = Join-Path $env:USERPROFILE '.local\bin'
$miseDataDir = Join-Path $env:LOCALAPPDATA 'mise'
$miseConfigDir = Join-Path $env:USERPROFILE '.config\mise'
$miseShimDir = Join-Path $miseDataDir 'shims'
$uvBinDir = $toolBinDir
```

| Location | Purpose |
| --- | --- |
| `%USERPROFILE%\.local\bin` | Portable mise, its companion shim executable, personal scripts, and uv tool/Python entries |
| `%USERPROFILE%\.config\mise\config.toml` | Global mise declarations |
| `%LOCALAPPDATA%\mise` | mise-installed tools and shims |
| `%APPDATA%\uv\data` | uv-managed Python interpreters and direct tool environments |
| `%LOCALAPPDATA%\uv\cache` | uv package cache |
| `%LOCALAPPDATA%\pnpm` | pnpm data, selected by `PNPM_HOME` |

These are default locations on a fresh Windows user profile. Windows known folders may resolve to another drive if redirected. [mise directories](https://mise.jdx.dev/directories.html), [uv storage](https://docs.astral.sh/uv/reference/storage/)

## 3. Install portable mise and configure PATH

Download the current `windows-x64.zip` release from [mise releases](https://github.com/jdx/mise/releases/latest), extract it, and locate its `mise\bin` directory containing `mise.exe` and `mise-shim.exe`. When prompted below, enter that extracted directory. [Official Windows instructions](https://mise.jdx.dev/installing-mise.html#manual-install-on-windows)

```powershell
New-Item -ItemType Directory -Force -Path $toolBinDir | Out-Null
$miseSourceDir = Read-Host 'Full path to the extracted mise\bin directory'
Copy-Item -LiteralPath (Join-Path $miseSourceDir 'mise.exe'),(Join-Path $miseSourceDir 'mise-shim.exe') -Destination $toolBinDir

# Persist the base environment for terminals, IDEs, and -NoProfile sessions.
$requiredPaths = @($miseShimDir, $toolBinDir, $uvBinDir) | Select-Object -Unique
$userPathEntries = [Environment]::GetEnvironmentVariable('Path', 'User') -split ';'
$newUserPath = ((@($requiredPaths) + @($userPathEntries)) | Where-Object { $_ } | Select-Object -Unique) -join ';'
[Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')

# Make the same entries available in this setup session.
$env:Path = ((@($requiredPaths) + @($env:Path -split ';')) | Where-Object { $_ } | Select-Object -Unique) -join ';'
mise --version
```

Keep `mise.exe` and `mise-shim.exe` together. The shims directory will be populated by mise as tools are installed. This portable installation is updated with `mise self-update`.

## 4. Copy the global configuration and install tools

```powershell
New-Item -ItemType Directory -Force -Path $miseConfigDir | Out-Null
Copy-Item -LiteralPath (Join-Path $repoRoot 'setup-guide/mise-configs/config.windows.toml') -Destination (Join-Path $miseConfigDir 'config.toml')

Push-Location -LiteralPath $HOME
try {
  mise install
  if ($LASTEXITCODE -ne 0) { throw 'Failed to install the configured tools.' }
}
finally {
  Pop-Location
}
```

Review the copied TOML to choose which tools to install. It contains six groups: runtime managers, runtimes/development environment, CLI tools, npm CLIs, Python CLIs, and other backends.

uv manages Python interpreters for the `pypi:` CLIs; ast-outline and ninja do not fix a Python version. Node remains declared for `npm:` CLIs. See [tool ownership](./README.md#tool-ownership).

## 5. Set PNPM_HOME and PATH

Set pnpm's data root and add its global command directory after the existing mise entries:

```powershell
$pnpmHome = Join-Path $env:LOCALAPPDATA 'pnpm'
$pnpmBinPath = Join-Path $pnpmHome 'bin'
New-Item -ItemType Directory -Force -Path $pnpmBinPath | Out-Null

[Environment]::SetEnvironmentVariable('PNPM_HOME', $pnpmHome, 'User')
$env:PNPM_HOME = $pnpmHome

$userPathEntries = [Environment]::GetEnvironmentVariable('Path', 'User') -split ';'
$newUserPath = ((@($userPathEntries) + @($pnpmBinPath)) | Where-Object { $_ } | Select-Object -Unique) -join ';'
[Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
$env:Path = ((@($env:Path -split ';') + @($pnpmBinPath)) | Where-Object { $_ } | Select-Object -Unique) -join ';'

mise exec -- pnpm store path
```

Keep pnpm's default cache and state locations. mise supplies the pnpm executable; `PNPM_HOME` controls package-manager data.

## 6. Set Bun's global bin PATH

Bun uses its own default data directories. Add its global command directory to PATH:

```powershell
$bunBinPath = Join-Path $env:USERPROFILE '.bun\bin'
$userPathEntries = [Environment]::GetEnvironmentVariable('Path', 'User') -split ';'
$newUserPath = ((@($userPathEntries) + @($bunBinPath)) | Where-Object { $_ } | Select-Object -Unique) -join ';'
[Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
$env:Path = ((@($env:Path -split ';') + @($bunBinPath)) | Where-Object { $_ } | Select-Object -Unique) -join ';'
```

Leave Bun's directory environment variables unset. mise shims remain before both package managers' global bin directories so mise continues to select the executable versions.

## 7. Set the default Java environment and PowerShell profile

After Java installation succeeds, persist its stable global JDK path:

```powershell
$javaHome = Join-Path $miseDataDir 'installs\java\global'
if (-not (Test-Path -LiteralPath (Join-Path $javaHome 'bin\java.exe'))) {
  throw 'Install the global Java declaration before setting JAVA_HOME.'
}
[Environment]::SetEnvironmentVariable('JAVA_HOME', $javaHome, 'User')
$env:JAVA_HOME = $javaHome

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PROFILE) | Out-Null
Copy-Item -LiteralPath (Join-Path $repoRoot 'wt-setting/Microsoft.PowerShell_profile.ps1') -Destination $PROFILE
code $PROFILE
```

Set the profile's `$gitBashBin` to the installed Git directory if you want Git Bash preferred over WSL Bash. For this guide's Scoop Git installation, the bin directory is `%USERPROFILE%\scoop\apps\git\current\bin`. The [profile notes](../wt-setting/) explain its contents.

Java uses ordinary Liberica and follows the latest LTS when upgraded. mise maintains the `global` link. Profile activation can set the session's project-specific `JAVA_HOME`; commands needing a complete project environment can use `mise exec -- .\gradlew.bat build`. [Java settings](https://mise.jdx.dev/lang/java.html), [global link](https://mise.jdx.dev/ide-integration.html#a-fixed-path-to-the-global-version)

## 8. Optional Python tools and private variables

Install MinerU separately only when needed:

```powershell
mise exec -- uv tool install 'mineru[all]' --python 3.12
```

Check [MinerU installation requirements](https://github.com/opendatalab/MinerU#installation) for the backend and hardware you use. Its Python 3.12 environment stays directly managed by uv.

Projects can request Python through uv as needed:

```powershell
mise exec -- uv python install 3.12
```

Follow the [environment-variable guide](../env_var/) to import private settings from `$HOME/.env_var`.

## 9. Verify and install update scripts

Fully exit and reopen Windows Terminal, the IDE, and other applications that need the persistent environment. In a fresh PowerShell session, check:

```powershell
mise ls --current
Get-Command mise,uv,node,pnpm,bun,java,ast-outline,ninja
uv --version
node --version
pnpm --version
java -version
& (Join-Path $env:JAVA_HOME 'bin\java.exe') -version
uv tool list
```

Check the inherited base environment without a profile:

```powershell
pwsh -NoLogo -NoProfile -Command 'Get-Command uv,node,pnpm,java; & (Join-Path $env:JAVA_HOME "bin\java.exe") -version'
```

mise-managed Python CLIs are separate from the direct uv list; that list contains MinerU if you installed it.

Follow the [update-script guide](../script/) to copy the updater and Task Scheduler launcher into `%USERPROFILE%\.local\bin`.
