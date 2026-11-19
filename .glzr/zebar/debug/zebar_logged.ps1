# Temporary launcher used by GlazeWM's startup_commands while the battery
# investigation runs: starts Zebar with stdout (its INFO log, which includes
# every provider emission) captured to a timestamped file in this folder.
# A plain `zebar` launch logs nothing to disk except ERROR-level lines.
#
# Undo: in ~/.glzr/glazewm/config.yaml, restore
#   startup_commands: ['shell-exec zebar']
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
Start-Process -FilePath 'C:\Program Files\glzr.io\Zebar\zebar.exe' `
  -RedirectStandardOutput (Join-Path $dir "zebar_$ts.log") `
  -RedirectStandardError (Join-Path $dir "zebar_${ts}_err.log") `
  -WindowStyle Hidden
