# Requires -RunAsAdministrator
if ($PSVersionTable.PSVersion.Major -gt 5) {
    # If called inside PowerShell 7, seamlessly pass execution down to Windows PowerShell v5
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File $MyInvocation.MyCommand.Path
    Exit
}

# The native engine payload
$List = Get-WinUserLanguageList
$Target = $List | Where-Object LanguageTag -eq 'en-US'
if ($Target) {
    $List.Remove($Target)
    Set-WinUserLanguageList $List -Force
}
