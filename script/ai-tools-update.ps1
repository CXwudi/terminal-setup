# Sets the preference for PowerShell native cmdlets to stop on error
$ErrorActionPreference = 'Stop'

# Helper function to stop script if an external program (like scoop/npm) fails
function Check-Exit {
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Execution stopped due to error."
        exit $LASTEXITCODE
    }
}

Write-Host "🚀 Starting update process..." -ForegroundColor Cyan

# --- SCOOP ---
Write-Host "🍨 Updating scoop..." -ForegroundColor Green
scoop update
Check-Exit

scoop update *
Check-Exit

scoop cleanup *
Check-Exit

# --- MISE ---
Write-Host "📦 Updating mise core and tools..." -ForegroundColor Green
mise self-update -y
Check-Exit

mise up
Check-Exit

# --- UV ---
Write-Host "🐍 Updating uv and tools..." -ForegroundColor Green
uv self update
Check-Exit

uv tool upgrade --all
Check-Exit

# --- PNPM --- 
Write-Host "📦 Updating global pnpm packages & approving builds..." -ForegroundColor Green
pnpm up -g --latest
Check-Exit

pnpm approve-builds --all
Check-Exit

## --- PI ---
Write-Host "🤖 Updating Pi plugins..." -ForegroundColor Green
pi update --extensions
Check-Exit

Write-Host "✅ All updates complete!" -ForegroundColor Cyan

