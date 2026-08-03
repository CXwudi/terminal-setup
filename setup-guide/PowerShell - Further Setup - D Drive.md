# Further Setup (D Drive) - scoop, uv, mise, node, pnpm, bun, AI CLIs

<!-- markdownlint-disable MD013 -->

Use this guide if you want to keep dev tools and related data under
`D:\local\...`.

## 1. Install Scoop (Windows)

Scoop is a command-line installer for Windows that makes it easy to install and
manage CLI tools.

If you have a D drive and want to keep dev tools there:

```powershell
# Set execution policy (required for Scoop)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install Scoop to D drive (using -ScoopDir and -ScoopGlobalDir parameters)
iex "& {$(irm get.scoop.sh)} -ScoopDir 'D:\local\scoop' -ScoopGlobalDir 'D:\scoop-global-app'"

# Verify installation
scoop --version
Get-Command scoop

# Install git if needed (required for bucket management)
# scoop install git

# Add extras bucket (optional, for more apps)
scoop bucket add extras
```

> **D Drive directory layout:**
>
> - `D:\local\scoop\` - Main installation directory (user installs)
> - `D:\local\scoop\apps\` - Installed applications
> - `D:\local\scoop\buckets\` - Bucket repositories
> - `D:\local\scoop\cache\` - Download cache
> - `D:\local\scoop\shims\` - Shims (added to PATH)
> - `D:\scoop-global-app\` - Global installs (`scoop install -g`, requires
>   admin)

## 2. Install CLI tools via Scoop

After Scoop is installed and the extras bucket is added, install these CLI
tools:

```powershell
# Install CLI tools via Scoop
scoop install yq           # YAML/JSON processor
scoop install ast-grep     # structural code search (alias: sg)
scoop install ripgrep      # fast text search (rg)
scoop install lsd          # modern ls command (from extras bucket)
scoop install just         # modern command runner
scoop install fzf          # fuzzy finder (just's suggestion)
scoop install gh           # GitHub CLI
scoop install psmux        # tmux-like terminal multiplexer for PowerShell
```

## 3. Install uv (Windows)

If you have a D drive and want to keep dev tools there:

```powershell
# Create D drive directory structure
New-Item -ItemType Directory -Force -Path "D:\local\bin" | Out-Null
New-Item -ItemType Directory -Force -Path "D:\local\uv" | Out-Null

# Set UV installation directory (must be set BEFORE running installer)
$env:UV_INSTALL_DIR = "D:\local\bin"

# Install uv
irm https://astral.sh/uv/install.ps1 | iex

# Set all UV directories permanently as user environment variables
[Environment]::SetEnvironmentVariable('UV_INSTALL_DIR', 'D:\local\bin', 'User')
[Environment]::SetEnvironmentVariable('UV_CACHE_DIR', 'D:\local\uv\cache', 'User')
[Environment]::SetEnvironmentVariable('UV_PYTHON_INSTALL_DIR', 'D:\local\uv\python', 'User')
[Environment]::SetEnvironmentVariable('UV_TOOL_DIR', 'D:\local\uv\tools', 'User')
[Environment]::SetEnvironmentVariable('UV_TOOL_BIN_DIR', 'D:\local\uv\bin', 'User')
[Environment]::SetEnvironmentVariable('UV_PYTHON_BIN_DIR', 'D:\local\uv\bin', 'User')

# Add D:\local\bin to user PATH (if not already present)
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*D:\local\bin*") {
  $newUserPath = if ([string]::IsNullOrEmpty($userPath)) { 'D:\local\bin' } else { "$userPath;D:\local\bin" }
  [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
}

# Add %UV_TOOL_BIN_DIR% to user PATH (if not already present)
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$uvToolBinDir = 'D:\local\uv\bin'
if ($userPath -notlike "*%UV_TOOL_BIN_DIR%*" -and $userPath -notlike "*$uvToolBinDir*") {
  $newUserPath = if ([string]::IsNullOrEmpty($userPath)) { '%UV_TOOL_BIN_DIR%' } else { "$userPath;%UV_TOOL_BIN_DIR%" }
  [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
}

# Refresh current session
$env:Path = "D:\local\bin;D:\local\uv\bin;$env:Path"

# Verify installation
uv --version
Get-Command uv
```

> **D Drive directory layout:**
>
> - `D:\local\bin\` - `uv.exe` only
> - `D:\local\uv\bin\` - Tool executables and Python symlinks
> - `D:\local\uv\cache\` - Package cache
> - `D:\local\uv\python\` - Python installations
> - `D:\local\uv\tools\` - Managed tools data

### Optional: Manage Python versions with uv

```powershell
# Install a specific Python version
uv python install 3.14
```

## 4. Install tools via uv

The tool `mineru[all]` requires high-end GPU and complicated CUDA setup, always
best to check latest guide.

```powershell
uv tool install 'mineru[all]' --python 3.12
```

Other tools:

```powershell
uv tool install ast-outline
```

## 5. Download and Configure mise for PowerShell

First, download the mise installer using `winget`:

```powershell
# Get the actual Downloads folder path (handles custom locations)
$downloadDir = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
$wingetDir = Join-Path $downloadDir 'winget'
New-Item -ItemType Directory -Force -Path $wingetDir | Out-Null

# Download mise installer
winget download --id JDX.Mise -d $wingetDir --skip-dependencies
Write-Host "mise installer downloaded to $wingetDir. Run it manually to complete installation." -ForegroundColor Green
```

Before running the downloaded installer, set the D drive environment variables
so the installer uses the right locations:

```powershell
# Create D drive directory structure for mise
New-Item -ItemType Directory -Force -Path "D:\local\mise" | Out-Null

# Set mise directories permanently as user environment variables
# Must be set BEFORE running mise installer for them to take effect
[Environment]::SetEnvironmentVariable('MISE_DATA_DIR', 'D:\local\mise', 'User')
[Environment]::SetEnvironmentVariable('MISE_CACHE_DIR', 'D:\local\mise\cache', 'User')
[Environment]::SetEnvironmentVariable('MISE_STATE_DIR', 'D:\local\mise\state', 'User')
[Environment]::SetEnvironmentVariable('MISE_CONFIG_DIR', 'D:\local\mise\config', 'User')

# Also set in current session for immediate effect
$env:MISE_DATA_DIR = "D:\local\mise"
$env:MISE_CACHE_DIR = "D:\local\mise\cache"
$env:MISE_STATE_DIR = "D:\local\mise\state"
$env:MISE_CONFIG_DIR = "D:\local\mise\config"
```

Run the downloaded installer manually. After it finishes, configure mise shims
and activate it in your PowerShell profile:

```powershell
# Add mise shims to user PATH (if not already present)
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$miseShimPath = 'D:\local\mise\shims'
if ($userPath -notlike "*%MISE_DATA_DIR%*" -and $userPath -notlike "*$miseShimPath*") {
  $newUserPath = if ([string]::IsNullOrEmpty($userPath)) { '%MISE_DATA_DIR%\shims' } else { "$userPath;%MISE_DATA_DIR%\shims" }
  [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
}

# Ensure profile exists
if (-not (Test-Path $PROFILE)) {
  New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# Add mise activate on profile
echo 'mise activate pwsh | Out-String | Invoke-Expression' >> $PROFILE

Write-Host "Profile updated. Restart PowerShell to use mise." -ForegroundColor Green
```

> **D Drive directory layout:**
>
> - `D:\local\mise\` - Main data dir (installs, plugins, downloads)
> - `D:\local\mise\shims\` - Shims (added to PATH)
> - `D:\local\mise\cache\` - Cache directory
> - `D:\local\mise\state\` - State directory
> - `D:\local\mise\config\` - Config directory

## 6. Install Tools via mise

After mise is installed and active in your PowerShell session,
copy the [`config.windows.toml`](mise-configs/config.windows.toml) into `$env:MISE_CONFIG_DIR\config.toml`

Then run:

```powershell
# Install tools defined in config.toml
mise install

# Check versions
node -v
pnpm -v
```

## 7. Set PNPM_HOME and PATH

Run this **once** to permanently configure `PNPM_HOME` as a Windows user
environment variable and add pnpm's v11 global binary directory to PATH:

If you have a D drive and want to keep dev tools there (recommended if your
projects are on D drive for hardlink performance):

```powershell
# Set PNPM_HOME to D drive location
$pnpmHome = "D:\local\pnpm"
$pnpmBinPath = Join-Path $pnpmHome 'bin'

# Create D drive directory structure for pnpm
New-Item -ItemType Directory -Force -Path $pnpmHome | Out-Null
New-Item -ItemType Directory -Force -Path $pnpmBinPath | Out-Null
New-Item -ItemType Directory -Force -Path "$pnpmHome\global" | Out-Null
New-Item -ItemType Directory -Force -Path "$pnpmHome\store" | Out-Null
New-Item -ItemType Directory -Force -Path "$pnpmHome\cache" | Out-Null
New-Item -ItemType Directory -Force -Path "$pnpmHome\state" | Out-Null

# Set PNPM_HOME as a permanent user environment variable
[Environment]::SetEnvironmentVariable('PNPM_HOME', $pnpmHome, 'User')

# Append %PNPM_HOME%\bin to user PATH if not already there
$pnpmPathEntry = '%PNPM_HOME%\bin'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$pnpmPathEntry*" -and $userPath -notlike "*$pnpmBinPath*") {
  $newUserPath = if ([string]::IsNullOrEmpty($userPath)) { $pnpmPathEntry } else { "$userPath;$pnpmPathEntry" }
  [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
}

# Refresh current session environment
$env:PNPM_HOME = $pnpmHome
$env:Path = "$pnpmBinPath;$env:Path"

# Starting pnpm v11, store / global / bin are derived from PNPM_HOME automatically:
#   store -> %PNPM_HOME%\store   global -> %PNPM_HOME%\global   bin -> %PNPM_HOME%\bin
# Only cache and state are NOT covered by PNPM_HOME, so set them explicitly.
# v11 writes these to the global config.yaml (NOT .npmrc); --location=global is the default.
pnpm config set cache-dir "$pnpmHome\cache" --location=global
pnpm config set state-dir "$pnpmHome\state" --location=global

# Update shims
mise reshim

# Verify: config.yaml keys + the PNPM_HOME-derived store should all point to D drive
pnpm config list
pnpm store path

Write-Host 'PNPM_HOME and PNPM_HOME\bin configured. Restart your terminal for PATH changes to fully take effect.' -ForegroundColor Green
```

> **D Drive directory layout:**
>
> - `D:\local\pnpm\` - `PNPM_HOME` root
> - `D:\local\pnpm\bin\` - Global package binaries (added to PATH)
> - `D:\local\pnpm\global\` - Global package installations and metadata
> - `D:\local\pnpm\store\` - Content-addressable store (hardlinks source)
> - `D:\local\pnpm\cache\` - Package cache
> - `D:\local\pnpm\state\` - State directory
>
> Keep each project's virtual store inside the project directory. Avoid setting
> `virtual-store-dir` globally unless you have a project-specific need.
>
> **Note:** This sets the environment variables at the Windows user level
> (permanent). If you prefer, you can manually set them via: Windows Settings →
> System → About → Advanced system settings → Environment Variables.

## 8. Install Global Packages via pnpm

```powershell
# so far empty, we use mise for now
```

## 9. Set BUN Global Bin Path

Run this **once** to ensure Bun's global binaries are accessible from your PATH:

If you have a D drive and want to keep dev tools there (recommended if your
projects are on D drive for better performance):

```powershell
# Set BUN directories on D drive
$bunHome = "D:\local\bun"

# Create D drive directory structure for bun
New-Item -ItemType Directory -Force -Path $bunHome | Out-Null
New-Item -ItemType Directory -Force -Path "$bunHome\bin" | Out-Null
New-Item -ItemType Directory -Force -Path "$bunHome\install\global" | Out-Null
New-Item -ItemType Directory -Force -Path "$bunHome\install\cache" | Out-Null

# Set environment variables
[Environment]::SetEnvironmentVariable('BUN_INSTALL', $bunHome, 'User')
[Environment]::SetEnvironmentVariable('BUN_INSTALL_BIN', "$bunHome\bin", 'User')
[Environment]::SetEnvironmentVariable('BUN_INSTALL_GLOBAL_DIR', "$bunHome\install\global", 'User')
[Environment]::SetEnvironmentVariable('BUN_INSTALL_CACHE_DIR', "$bunHome\install\cache", 'User')

# Add %BUN_INSTALL_BIN% to user PATH if not already present
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$bunBinPath = "$bunHome\bin"
if ($userPath -notlike "*%BUN_INSTALL_BIN%*" -and $userPath -notlike "*$bunBinPath*") {
  $newUserPath = if ([string]::IsNullOrEmpty($userPath)) { '%BUN_INSTALL_BIN%' } else { "$userPath;%BUN_INSTALL_BIN%" }
  [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
}

# Refresh current session environment
$env:BUN_INSTALL = $bunHome
$env:BUN_INSTALL_BIN = "$bunHome\bin"
$env:BUN_INSTALL_GLOBAL_DIR = "$bunHome\install\global"
$env:BUN_INSTALL_CACHE_DIR = "$bunHome\install\cache"
$env:Path = "$bunHome\bin;$env:Path"

Write-Host 'Bun directories set permanently. Restart terminal for PATH changes to take effect.' -ForegroundColor Green
```

> **D Drive directory layout:**
>
> - `D:\local\bun\` - `BUN_INSTALL` (main directory)
> - `D:\local\bun\bin\` - Global binaries (added to PATH)
> - `D:\local\bun\install\global\` - Global packages
> - `D:\local\bun\install\cache\` - Package cache
>
> **Note:** Environment variables are used instead of `bunfig.toml` due to
> [known Windows issues](https://github.com/oven-sh/bun/issues/12886).

## 10. Install SDKMAN via Git Bash

Run this **once** in Git Bash to install SDKMAN and configure your shell (Git
Bash must be installed):

If you have a D drive and want to keep dev tools there:

```bash
# Add zip command (SDKMAN requires it, Git Bash has funzip built-in)
cp /usr/bin/funzip.exe /usr/bin/zip.exe

# Install SDKMAN to D drive without modifying .bashrc
export SDKMAN_DIR="/d/local/sdkman" && curl -s "https://get.sdkman.io?rcupdate=false" | bash

# Add SDKMAN to .bashrc
cat >> ~/.bashrc << 'EOF'

# SDKMAN
export SDKMAN_DIR="/d/local/sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
EOF

echo "SDKMAN installed. Restart Git Bash to use sdk command."
```

> **D Drive directory layout:**
>
> - `D:\local\sdkman\` - Main SDKMAN directory
> - `D:\local\sdkman\candidates\` - Installed SDKs (Java, Gradle, etc.)
> - `D:\local\sdkman\archives\` - Downloaded archives
> - `D:\local\sdkman\tmp\` - Temporary files

### Install Liberica NIK (GraalVM-based JDK)

After restarting Git Bash:

```bash
# Verify SDKMAN
sdk version

# List available Liberica NIK versions
sdk list java | grep nik

# Install Liberica NIK LTS (example version)
sdk install java 23.1.5.r21-nik

# Set as default
sdk default java 23.1.5.r21-nik

# Verify
java -version
```
