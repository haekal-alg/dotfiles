' Runs zebar_logged.ps1 with no console window. GlazeWM's shell-exec would
' flash a console if it launched powershell directly; wscript with window
' style 0 keeps it fully hidden.
Set fso = CreateObject("Scripting.FileSystemObject")
dir = fso.GetParentFolderName(WScript.ScriptFullName)
CreateObject("WScript.Shell").Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & dir & "\zebar_logged.ps1""", 0, False
