(mise activate pwsh) | Out-String | Invoke-Expression

# Starship prints an error in non-interactive shells with TERM=dumb.
if ($env:TERM -ne 'dumb') {
  Invoke-Expression (&starship init powershell)
  if (Get-Command Enable-TransientPrompt -ErrorAction SilentlyContinue) {
    Enable-TransientPrompt
  }
}

# Prefer Git Bash over WSL bash.exe.
$gitBashBin = "D:\Program Files\Git\bin"

if (Test-Path (Join-Path $gitBashBin "bash.exe")) {
  $pathParts = $env:Path -split ";" |
    Where-Object { $_ -and ($_.TrimEnd("\") -ine $gitBashBin) }

  $env:Path = (@($gitBashBin) + $pathParts) -join ";"
}