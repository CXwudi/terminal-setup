# Settings for Windows Terminal and PowerShell 7+

## `settings.json`

Copy the content of `settings.json` to your Windows Terminal settings

This config contains:

1. All SSH profiles
2. Font: MesloLGS NF
3. Opacity of 75% with acrylic effect enabled
4. ctrl+backspace properly configured, effective on all profiles

## `Microsoft.PowerShell_profile.ps1`

Launch `code $PROFILE` in PowerShell and copy the content of `Microsoft.PowerShell_profile.ps1`

## Backup and restore tasks

With mise and PowerShell 7 installed, run from anywhere in this repository:

```powershell
mise tasks --all
mise run //wt-setting:backup
mise run //wt-setting:restore
```

`backup` copies the current Windows Terminal settings and PowerShell profile into this directory; `restore` copies those files back, overwriting the installed versions. Run the command for the operation you need. You can also run `//wt-setting:backup-terminal`, `//wt-setting:restore-terminal`, `//wt-setting:backup-powershell`, or `//wt-setting:restore-powershell` separately. Inside `wt-setting/`, use `mise run :backup` or `mise run :restore`. See [mise monorepo tasks](https://mise.jdx.dev/tasks/monorepo.html).
