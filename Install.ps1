<#
    Requires Powershell Version greater or equal to 3
    Requires a restart after setup
#>
[CmdletBinding()]
param(
  [string]$RegFile = "config.reg",
  [string]$InstallModules = "",
  [string]$Version = "EC105"
)
$ErrorActionPreference = "SilentlyContinue"
Import-Module -Name "$PSScriptRoot\Helper\Functions_Module.psm1"

#Set up variables
[string]$ScriptRoot = $PSScriptRoot
[string]$Temp = $env:temp
<#
  Edit this section, if updates or changes are made to the files
#>
class EC105 {
static [string]$BaseDir = "EC105"
static [string]$x64_Hash = "D8183AF53264867038B1500272D8D2BC"
static [string]$x86_Hash = "C0306C8798A7F0B858F658DE121C5C2D"
}
Class EC160 {
static [string]$BaseDir = "EC160"
static [string]$x64_Hash = "A32B760F619E45910622580DEE70C82B"
static [string]$x86_Hash = "C3A3BC7437F7470D5EFEB81DBC31728D"
}
Class EC162 {
static [string]$BaseDir = "EC162"
static [string]$x64_Hash = "9DAB7022D2FCA35740601BB02737C146"
static [string]$x86_Hash = "1306DC46B4E1BB2BACAD1F153DB5A17D"
}
<#
  End of edit section
#>
<#
	Begin installation
	Installation Enterprise Connect
#>
#Update der Registrierungseintraege
if([string]::IsNullOrEmpty($RegFile))
{
  Write-Host "RegFile $ScriptRoot\$RegFile not set, aborting..."
  Exit 1
}
Write-Host "$InstallModules"
if(-Not (($InstallModules -like '*Core*') -or ([string]::IsNullOrEmpty($InstallModules)))) {
  Write-Host "ERROR: You specified only specific Modules but forgot to specify `"Core`". Aborting...."
  Exit 1
}
#We have to remove spaces, because broken Parameter ADDLOCAL
#https://stackoverflow.com/questions/24355760/removing-spaces-from-a-variable-thats-user-inputted-in-powershell-4-0/24356297
$InstallModules = $InstallModules -replace '\s',''
$exitCode = execInProc "cmd" "/c regedit /s `"$RegFile`""
evaulateResultCode $exitCode $RegFile

switch ($Version)
{
  "EC105" {$InstallVersion = [EC105]}
  "EC160" {$InstallVersion = [EC160]}
  "EC162" {$InstallVersion = [EC162]}
}

Write-Host "Installing $InstallVersion"
# Check if 32bit or 64bit OS, store to value
Write-Host "Determining OS Type..."
Write-Host "Building path..."
$Path = normalizePath $ScriptRoot $InstallVersion::BaseDir
Write-Host "built path"
if ([System.IntPtr]::Size -eq 4) {
  #32Bit
  Write-Host "Detected 32bit OS."
  Get-ChildItem $Path | Foreach-Object {
    $item = normalizePath $Path $_
    if((Get-Item $item) -is [System.IO.FileInfo]) {
      if($InstallVersion::x86_Hash -eq (Get-FileHash -Algorithm "MD5" $item).Hash) {
        Write-Host "Found file $item for installation."
        if([string]::IsNullOrEmpty($InstallModules))
        {
          $exitCode = execInProc "msiexec.exe" "/passive /norestart /i `"$item`""
        } else {
          $exitCode = execInProc "msiexec.exe" "/passive /norestart /i `"$item`" ADDLOCAL=`"$InstallModules`""
        }
        evaulateResultCode $exitCode $item
      }
    }
  }
}
else {
  #64Bit
  Write-Host "Detected 64bit OS."
  Get-ChildItem $Path | Foreach-Object {
    $item = normalizePath $Path $_
    if((Get-Item $item) -is [System.IO.FileInfo]) {
      if($InstallVersion::x64_Hash -eq (Get-FileHash -Algorithm "MD5" $item).Hash) {
        Write-Host "Found file $item for installation."
        if([string]::IsNullOrEmpty($InstallModules))
        {
          $exitCode = execInProc "msiexec.exe" "/passive /norestart /i `"$item`""
        } else {
          write-Host "msiexec.exe" "/passive /norestart /i `"$item`" ADDLOCAL=`"$InstallModules`""
          $exitCode = execInProc "msiexec.exe" "/passive /norestart /i `"$item`" ADDLOCAL=`"$InstallModules`""
        }
        evaulateResultCode $exitCode $item
      }
    }
  }
}
