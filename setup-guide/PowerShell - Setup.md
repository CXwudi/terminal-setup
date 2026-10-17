# Set Up PowerShell 7 and Starship

## 1. Install PowerShell and a terminal font

Install PowerShell 7 if needed, then open it for the remaining commands:

```powershell
winget install --id Microsoft.PowerShell --exact
```

Install [MesloLGS NF using the font instructions](https://github.com/romkatv/powerlevel10k#manual-font-installation). Set the font in Windows Terminal's PowerShell appearance settings and in your IDE terminal settings.

## 2. Install Starship

```powershell
winget install --id Starship.Starship --exact
```

## 3. Configure the initial profile

Create the profile and open it:

```powershell
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PROFILE) | Out-Null
if (-not (Test-Path -LiteralPath $PROFILE)) {
  New-Item -ItemType File -Path $PROFILE | Out-Null
}
code $PROFILE
```

Copy the [PowerShell profile example](../wt-setting/Microsoft.PowerShell_profile.ps1) into it

## 4. Optional: Customize Starship

Starship uses `~/.config/starship.toml` by default. Generate a preset or edit the file directly:

```powershell
New-Item -ItemType Directory -Force -Path (Join-Path $HOME '.config') | Out-Null
starship preset nerd-font-symbols -o (Join-Path $HOME '.config/starship.toml')
```

See [Starship configuration](https://starship.rs/config/), then continue with the [Windows tooling setup](./PowerShell%20-%20Further%20Setup.md).
