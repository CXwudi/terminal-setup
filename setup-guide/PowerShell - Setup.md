# How to setup PowerShell 7 + starship

<!-- markdownlint-disable MD013 -->

website:

1. [starship](https://starship.rs/)
2. [mise (version manager)](https://mise.jdx.dev/)

## 1. Install Meslo Nerd Font

The MesloLGS NF fonts are already included in this repository (`.ttf` files).

To install:

- Double-click each `.ttf` file and click "Install"
- Or right-click → "Install for all users"

Configure the font in your terminals:

- **Windows Terminal**: Settings → Profiles → PowerShell → Appearance → Font
  face → "MesloLGS NF"
- **VSCode**: Settings → Terminal › Integrated: Font Family → `MesloLGS NF`
- **JetBrains IDEs**: Settings → Editor → Font → Fallback font → "MesloLGS NF"

## 2. Install core tools via winget

```powershell
# Install Starship
winget install -i Starship.Starship
```

Note: If you don't have PowerShell 7+ yet, install it first:

```powershell
winget download Microsoft.PowerShell
```

## 3. Configure PowerShell profile for starship

Run this **once** to add starship initialization to your PowerShell profile:

```powershell
# Create profile if missing
if (-not (Test-Path $PROFILE)) {
  New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# Add starship init on profile
echo '# Starship prints an error in non-interactive shells with TERM=dumb.
if ($env:TERM -ne 'dumb') {
  Invoke-Expression (&starship init powershell)
  if (Get-Command Enable-TransientPrompt -ErrorAction SilentlyContinue) {
    Enable-TransientPrompt
  }
}
' >> $PROFILE

Write-Host "Profile updated. Restart PowerShell to use starship." -ForegroundColor Green
```

After running this, **restart your PowerShell terminal**. You should see the
starship prompt.

## 4. (Optional) Customize starship

Starship uses a config file at `~/.config/starship.toml` (or
`$env:USERPROFILE\.config\starship.toml` on Windows).

You can:

- Use a preset: `starship preset nerd-font-symbols -o ~/.config/starship.toml`
- Or customize it manually by editing the file directly

See [starship configuration docs](https://starship.rs/config/) for all options.
