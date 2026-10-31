param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# ----------------------------
# Console / encoding setup
# ----------------------------

try {
    [Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)

    # Use normal host rendering.
    # This preserves colors in Windows Terminal without forcing ANSI into logs.
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $PSStyle.OutputRendering = 'Host'
    }
}
catch {
    Write-Warning "Failed to configure console encoding/rendering: $($_.Exception.Message)"
}

# ----------------------------
# Config
# ----------------------------

$UpdaterName = 'ai-tools-update.ps1'

# Optional:
# If Task Scheduler cannot find ai-tools-update.ps1 from PATH,
# hardcode the full path here.
#
# Example:
# $UpdaterPath = "$env:USERPROFILE\.local\bin\ai-tools-update.ps1"
#
$UpdaterPath = $null

$LogRetentionDays = 14
$RunOncePerCalendarDay = $true

$StateDir = Join-Path $env:LOCALAPPDATA 'ai-tools-update'
$LogDir = Join-Path $StateDir 'logs'
$LastSuccessFile = Join-Path $StateDir 'last-success.txt'
$ChildRunnerScript = Join-Path $StateDir 'run-ai-tools-update.child.ps1'

New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

$LogFile = $null

# ----------------------------
# Helper functions
# ----------------------------

function Get-CurrentPowerShellExe {
    try {
        $CurrentProcessPath = (Get-Process -Id $PID).Path

        if (-not [string]::IsNullOrWhiteSpace($CurrentProcessPath)) {
            return $CurrentProcessPath
        }
    }
    catch {}

    $PwshCommand = Get-Command 'pwsh.exe' -ErrorAction SilentlyContinue

    if ($PwshCommand) {
        return $PwshCommand.Source
    }

    return "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
}

function Remove-StaleLogs {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory,

        [Parameter(Mandatory = $true)]
        [int]$RetentionDays
    )

    try {
        $Cutoff = (Get-Date).AddDays(-$RetentionDays)

        Get-ChildItem -Path $Directory -Filter 'update-*.log' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $Cutoff } |
            Remove-Item -Force -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to clean old logs: $($_.Exception.Message)"
    }
}

function Test-AlreadySucceededToday {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return $false
    }

    try {
        $LastSuccessText = Get-Content -Path $Path -Raw
        $LastSuccess = [datetimeoffset]::Parse(
            $LastSuccessText.Trim(),
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::RoundtripKind
        )

        return ($LastSuccess.LocalDateTime.Date -eq (Get-Date).Date)
    }
    catch {
        Write-Warning "Could not read last success timestamp. Continuing with update."
        return $false
    }
}

function Convert-LogToPlainText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return
    }

    try {
        $Text = Get-Content -Path $Path -Raw -Encoding UTF8

        $Esc = [char]27

        # Remove ANSI CSI sequences, for example ESC[32m
        $Text = [regex]::Replace($Text, "$Esc\[[0-?]*[ -/]*[@-~]", '')

        # Remove ANSI OSC sequences, including hyperlink/title style sequences.
        $Text = [regex]::Replace($Text, "$Esc\][^\a]*?(\a|$Esc\\)", '')

        # Remove other escape/control-style sequences.
        $Text = [regex]::Replace(
            $Text,
            "$Esc[P\^_].*?$Esc\\",
            '',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

        $Text = [regex]::Replace($Text, "$Esc[@-_]", '')

        # Remove PowerShell transcript boilerplate.
        $Text = [regex]::Replace(
            $Text,
            '(?ms)^\*{10,}\r?\nPowerShell transcript start.*?^\*{10,}\r?\n',
            ''
        )

        $Text = [regex]::Replace(
            $Text,
            '(?ms)^\*{10,}\r?\nPowerShell transcript end.*?^\*{10,}\r?\n',
            ''
        )

        $Text = [regex]::Replace(
            $Text,
            '(?m)^Transcript (started|stopped), output file is .*\r?\n?',
            ''
        )

        # Convert lone carriage returns from progress output into normal newlines.
        $Text = $Text -replace "`r(?!`n)", "`r`n"

        # Remove remaining non-printable control characters except tab/newline.
        $Text = [regex]::Replace($Text, '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '')

        # Normalize line endings.
        $Text = $Text -replace "`r?`n", "`r`n"

        Set-Content -Path $Path -Value $Text -Encoding UTF8 -NoNewline
    }
    catch {
        Write-Warning "Failed to sanitize log file: $($_.Exception.Message)"
    }
}

function Write-ChildRunnerScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $RunnerContent = @'
param(
    [Parameter(Mandatory = $true)]
    [string]$Updater,

    [Parameter(Mandatory = $true)]
    [string]$LogFile
)

$ErrorActionPreference = 'Stop'

try {
    [Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $PSStyle.OutputRendering = 'Host'
    }
}
catch {}

$TranscriptStarted = $false

try {
    $TranscriptParams = @{
        Path   = $LogFile
        Append = $true
        Force  = $true
    }

    if ((Get-Command Start-Transcript).Parameters.ContainsKey('UseMinimalHeader')) {
        $TranscriptParams.UseMinimalHeader = $true
    }

    Start-Transcript @TranscriptParams | Out-Null
    $TranscriptStarted = $true
}
catch {
    Write-Warning "Failed to start transcript log: $($_.Exception.Message)"
}

$ExitCode = 0

try {
    & $Updater

    if ($global:LASTEXITCODE -is [int]) {
        $ExitCode = $global:LASTEXITCODE
    }
}
catch {
    Write-Error $_
    $ExitCode = 1
}
finally {
    if ($TranscriptStarted) {
        try {
            Stop-Transcript | Out-Null
        }
        catch {}
    }
}

exit $ExitCode
'@

    Set-Content -Path $Path -Value $RunnerContent -Encoding UTF8
}

# ----------------------------
# Main
# ----------------------------

$MutexName = 'Local\ai-tools-update-startup-mutex'
$Mutex = [System.Threading.Mutex]::new($false, $MutexName)
$HasMutex = $false

try {
    $HasMutex = $Mutex.WaitOne(0)

    if (-not $HasMutex) {
        Write-Host "Another ai-tools update is already running. Exiting."
        exit 0
    }

    Remove-StaleLogs -Directory $LogDir -RetentionDays $LogRetentionDays

    if (
        -not $Force `
        -and $RunOncePerCalendarDay `
        -and (Test-AlreadySucceededToday -Path $LastSuccessFile)
    ) {
        $LastSuccessText = Get-Content -Path $LastSuccessFile -Raw

        Write-Host "✅ ai-tools update already completed successfully today." -ForegroundColor Green
        Write-Host "Last success: $($LastSuccessText.Trim())"
        Write-Host "Use -Force to run anyway."
        exit 0
    }

    # Resolve updater script.
    if ([string]::IsNullOrWhiteSpace($UpdaterPath)) {
        $Updater = (Get-Command $UpdaterName -ErrorAction Stop).Source
    }
    else {
        $Updater = $UpdaterPath
    }

    if (-not (Test-Path $Updater)) {
        throw "Updater script not found: $Updater"
    }

    $PowerShellExe = Get-CurrentPowerShellExe

    $Timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $LogFile = Join-Path $LogDir "update-$Timestamp.log"

    Write-ChildRunnerScript -Path $ChildRunnerScript

    $StartedAt = Get-Date

    $Header = @(
        'AI Tools Update Log'
        '==================='
        "Started:    $($StartedAt.ToString('o'))"
        "Updater:    $Updater"
        "PowerShell: $PowerShellExe"
        "Machine:    $env:COMPUTERNAME"
        "User:       $env:USERNAME"
        ''
    )

    Set-Content -Path $LogFile -Value $Header -Encoding UTF8

    Write-Host "🚀 Running AI tools updater..." -ForegroundColor Cyan
    Write-Host "Updater: $Updater"
    Write-Host "PowerShell: $PowerShellExe"
    Write-Host "Log file: $LogFile"
    Write-Host "Log retention: $LogRetentionDays days"
    Write-Host ""

    # Important:
    # Do NOT pipe this through Tee-Object.
    # Let the child process inherit the real terminal so colors/emojis keep working.
    # Logging is handled by Start-Transcript inside the child process.
    & $PowerShellExe `
        -NoLogo `
        -ExecutionPolicy Bypass `
        -File $ChildRunnerScript `
        -Updater $Updater `
        -LogFile $LogFile

    $ExitCode = $LASTEXITCODE

    if ($null -eq $ExitCode) {
        $ExitCode = 1
    }

    $FinishedAt = Get-Date

    Convert-LogToPlainText -Path $LogFile

    Add-Content -Path $LogFile -Encoding UTF8 -Value @(
        ''
        '==================='
        "Finished:   $($FinishedAt.ToString('o'))"
        "Exit code:  $ExitCode"
    )

    if ($ExitCode -ne 0) {
        throw "ai-tools-update.ps1 failed with exit code $ExitCode."
    }

    $FinishedAt.ToString('o') | Set-Content -Path $LastSuccessFile -Encoding UTF8

    Write-Host ""
    Write-Host "✅ AI tools update completed successfully." -ForegroundColor Cyan
    Write-Host "Log file: $LogFile"
    Write-Host "Last success file: $LastSuccessFile"

    exit 0
}
catch {
    Write-Host ""
    Write-Host "❌ AI tools update failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""

    if (-not [string]::IsNullOrWhiteSpace($LogFile)) {
        Write-Host "Log file:" -ForegroundColor Yellow
        Write-Host $LogFile
        Write-Host ""
    }

    try {
        [console]::Beep(800, 500)
    }
    catch {}

    Read-Host "Press Enter to close this window"
    exit 1
}
finally {
    if ($HasMutex) {
        $Mutex.ReleaseMutex() | Out-Null
    }

    if ($null -ne $Mutex) {
        $Mutex.Dispose()
    }
}