# Further Setup (C Drive) - scoop, uv, mise, node, pnpm, bun, AI CLIs

<!-- markdownlint-disable MD013 -->

Use this guide if you want the default Windows install locations on `C:`.

## 1. Install Scoop (Windows)

Scoop is a command-line installer for Windows that makes it easy to install and
manage CLI tools.

```powershell
# Set execution policy (required for Scoop)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install Scoop
irm get.scoop.sh | iex

# Verify installation
scoop --version
Get-Command scoop

# Install git (required for bucket management)
scoop install git

# Add extras bucket (optional, for more apps)
scoop bucket add extras
```

The installer automatically installs Scoop to `$HOME\scoop` and adds it to PATH.

> **Note:** The extras bucket is needed for some tools like `lsd` in Step 2.

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

```powershell
# Install uv using the official PowerShell script
irm https://astral.sh/uv/install.ps1 | iex

# Verify installation
uv --version
Get-Command uv
```

The installer should automatically add `$USERPROFILE/.local/bin` to the PATH,
and put `uv.exe` there.

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

After running the downloaded mise installer, configure mise shims and activate
it in your PowerShell profile:

```powershell
# Ensure profile exists
if (-not (Test-Path $PROFILE)) {
  New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# Add mise shims to user PATH (if not already present)
$shimPath = "$env:USERPROFILE\AppData\Local\mise\shims"
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$shimPath*") {
  $newUserPath = if ([string]::IsNullOrEmpty($userPath)) { $shimPath } else { "$userPath;$shimPath" }
  [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
}

# Add mise activate on profile
echo 'mise activate pwsh | Out-String | Invoke-Expression' >> $PROFILE

Write-Host "Profile updated. Restart PowerShell to use mise." -ForegroundColor Green
```

## 6. Install Tools via mise

After mise is installed and active in your PowerShell session,
copy the [`config.windows.toml`](mise-configs/config.windows.toml) into `%USERPROFILE%\.config\mise\config.toml`

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

```powershell
# Set PNPM_HOME to Windows-standard location
$pnpmHome = "$env:LOCALAPPDATA\pnpm"
$pnpmBinPath = Join-Path $pnpmHome 'bin'

New-Item -ItemType Directory -Force -Path $pnpmHome | Out-Null
New-Item -ItemType Directory -Force -Path $pnpmBinPath | Out-Null

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

# Update shims
mise reshim

Write-Host 'PNPM_HOME and PNPM_HOME\bin configured. Restart your terminal for PATH changes to fully take effect.' -ForegroundColor Green
```

## 8. Install Global Packages via pnpm

```powershell
# so far empty, we use mise for now
```

## 9. Set BUN Global Bin Path

Run this **once** to ensure Bun's global binaries are accessible from your PATH:

Use Bun's default directories. Only add the default bin path to PATH for global
package binaries.

```powershell
# Add default Bun bin directory to user PATH if not already present
$bunBinPath = "$env:USERPROFILE\.bun\bin"
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')

if ($userPath -notlike "*$bunBinPath*" -and $userPath -notlike "*\.bun\bin*") {
  $newUserPath = if ([string]::IsNullOrEmpty($userPath)) { $bunBinPath } else { "$userPath;$bunBinPath" }
  [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
}

# Refresh current session PATH
$env:Path = "$bunBinPath;$env:Path"

Write-Host 'Bun bin path added to PATH. Restart terminal for changes to take effect.' -ForegroundColor Green
```

## 10. Install SDKMAN via Git Bash

Run this **once** in Git Bash to install SDKMAN and configure your shell (Git
Bash must be installed):

```bash
# Add zip command (SDKMAN requires it, Git Bash has funzip built-in)
cp /usr/bin/funzip.exe /usr/bin/zip.exe

# Install SDKMAN without modifying .bashrc
curl -s "https://get.sdkman.io?rcupdate=false" | bash

# Add SDKMAN to .bashrc
cat >> ~/.bashrc << 'EOF'

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
EOF

echo "SDKMAN installed. Restart Git Bash to use sdk command."
```

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
