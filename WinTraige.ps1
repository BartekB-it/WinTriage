Write-Host "WinTriage Script v0.4" -ForegroundColor Magenta

$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	Write-Host "[!] WARNING: Not running as Administrator! Event Logs and some Network data will be missing." -ForegroundColor Red -BackgroundColor Black
	Write-Host "[!] Please restart PowerShell as Administrator to get full results. `n" -ForegroundColor Red
}

# Settings---

# Add/remove/modify paths for processes to your convenience
$ProcessPaths = @("$env:LOCALAPPDATA", "$env:TEMP",  "C:\Temp", "$env:LOCALAPPDATA\Roaming", "$env:LOCALAPPDATA\Roaming\Microsoft\Windows\Start", "C:\Users\Public", "C:\Windows\Temp", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup", "$env:APPDATA", "$env:USERPROFILE\AppData\LocalLow", "$env:USERPROFILE\Downloads")

# Add/remove/modify registry paths to your convenience
$RegistryPaths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce", "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunServices", "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunServices", "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce", "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run", "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Userinit", "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell", "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Notify", "HKLM:\System\CurrentControlSet\Control\Session Manager", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders")

# Change $Days value for how many past days you want to have the logs checked within
$LogsDays = 14
# Add/remove/modify event ids you want to be checked
$EventIdsSecurity = @("1102", "4625", "4720", "4738", "4698", "4697", "4648", "4732", "4756", "104", "1116", "1117")
$EventIdsSystem = @("7045")
$EventIdsPSOperational = @("4104")

#Taking a todays date to make a folder for the report
$dateStr = (Get-Date).ToString('dd-MM-yyyy-HH-mm')

# Checking if the report folder exists on the Dekstop
$ReportDir = "$env:USERPROFILE\Desktop\WinTriage-report\$dateStr"
if (-Not (Test-Path -Path $ReportDir)) {
New-Item -Path $ReportDir -ItemType Directory -Force | Out-Null
}

# End of Settings---

Write-Host "`n[!] Checking processes..." -ForegroundColor Magenta

Get-CimInstance -Query "SELECT * FROM Win32_Process WHERE CommandLine Like '%powershell%'" -ErrorAction 'SilentlyContinue' | Export-Csv -Path "$env:USERPROFILE\Desktop\WinTriage-report\$dateStr\powershell.csv" -NoTypeInformation
$AllProcesses = Get-Process
$ProcessPaths | ForEach-Object { $AllProcesses | where {$_.Path -match $_}} -ErrorAction 'SilentlyContinue' | Export-Csv -Path "$env:USERPROFILE\Desktop\WinTriage-report\$dateStr\temp-folders.csv" -NoTypeInformation

Write-Host "`n[!] Checking registry..." -ForegroundColor Magenta

$RegistryPaths | ForEach-Object { Get-ItemProperty -Path $_ } -ErrorAction 'SilentlyContinue' 2>$null | Export-Csv -Path "$env:USERPROFILE\Desktop\WinTriage-report\$dateStr\registry.csv" -NoTypeInformation

Write-Host "`n[!] Checking scheduled tasks..." -ForegroundColor Magenta

Get-ScheduledTask | Select TaskName,Actions,Author -ErrorAction 'SilentlyContinue' | Where-Object Author -NotLike "Microsoft Corporation" | Export-Csv -Path "$env:USERPROFILE\Desktop\WinTriage-report\$dateStr\scheduled-tasks.csv" -NoTypeInformation

Write-Host "`n[!] Checking TCP connections..." -ForegroundColor Magenta

get-nettcpconnection | select local*,remote*,state,@{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}} -ErrorAction 'SilentlyContinue' | Export-Csv -Path "$env:USERPROFILE\Desktop\WinTriage-report\$dateStr\tcp-connections.csv" -NoTypeInformation

Write-Host "`n[!] Checking Event logs..." -ForegroundColor Magenta

$Date = (Get-Date).AddDays(-$LogsDays)
$EventIdsSecurity | ForEach-Object { Get-WinEvent -FilterHashtable @{ LogName='Security'; StartTime=$Date; Id=$_} } -ErrorAction 'SilentlyContinue' 2>$null | Export-Csv -Path "$env:USERPROFILE\Desktop\WinTriage-report\$dateStr\security.csv" -NoTypeInformation
$EventIdsSystem | ForEach-Object { Get-WinEvent -FilterHashtable @{ LogName='System'; StartTime=$Date; Id=$_} } -ErrorAction 'SilentlyContinue' 2>$null | Export-Csv -Path "$env:USERPROFILE\Desktop\WinTriage-report\$dateStr\system.csv" -NoTypeInformation
$EventIdsPSOperational | ForEach-Object { Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-PowerShell/Operational'; StartTime=$Date; Id=$_} } -ErrorAction 'SilentlyContinue' 2>$null | Export-Csv -Path "$env:USERPROFILE\Desktop\WinTriage-report\$dateStr\psoperational.csv" -NoTypeInformation

Write-Host "`n[!] Checking DNS Cache..." -ForegroundColor Magenta

Get-DnsClientCache -ErrorAction 'SilentlyContinue' | Export-Csv -Path "$env:USERPROFILE\Desktop\WinTriage-report\$dateStr\dns-cache.csv" -NoTypeInformation

Write-Host "`n[!] Checking Local Users..." -ForegroundColor Magenta

Get-LocalUser -ErrorAction 'SilentlyContinue' | Export-Csv -Path "$env:USERPROFILE\Desktop\WinTriage-report\$dateStr\local-users.csv" -NoTypeInformation

Write-Host "`n[!] Now conveniently check all the data you have in 'WinTriage-report' - good luck, hunter!" -ForegroundColor Magenta
