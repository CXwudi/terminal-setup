# Update global tools from the user's home, outside project mise configurations.
$ErrorActionPreference = 'Stop'

# Stop before the next update step when a native command fails.
function Check-Exit {
    if ($LASTEXITCODE -ne 0) {
        throw "Update command failed with exit code $LASTEXITCODE."
    }
}

# Use the executable directly, including when a profile defines a mise function.
$miseBin = (Get-Command mise -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source

Push-Location -LiteralPath $HOME
try {
    Write-Host "🚀 Starting update process..." -ForegroundColor Cyan

    Write-Host "🍨 Updating Scoop and its tools..." -ForegroundColor Green
    scoop update
    Check-Exit
    scoop update '*'
    Check-Exit
    scoop cleanup '*'
    Check-Exit

    Write-Host "📦 Updating mise and its managed tools..." -ForegroundColor Green
    & $miseBin self-update -y
    Check-Exit
    & $miseBin upgrade
    Check-Exit
    & $miseBin prune --tools -y
    Check-Exit

    Write-Host "📦 Updating tools managed directly by pnpm..." -ForegroundColor Green
    & $miseBin exec -- pnpm update --global --latest
    Check-Exit
    & $miseBin exec -- pnpm store prune
    Check-Exit

    Write-Host "🐍 Updating tools managed directly by uv..." -ForegroundColor Green
    & $miseBin exec -- uv tool upgrade --all
    Check-Exit
    & $miseBin exec -- uv cache prune
    Check-Exit

    Write-Host "🤖 Updating Pi extensions..." -ForegroundColor Green
    & $miseBin exec -- pi update --extensions
    Check-Exit

    Write-Host "🖥️ Updating cua-driver..." -ForegroundColor Green
    cua-driver update --apply
    Check-Exit

    Write-Host "✅ All updates complete!" -ForegroundColor Cyan
}
finally {
    Pop-Location
}
