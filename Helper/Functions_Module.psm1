<#
    Requires Powershell Version greater or equal to 3
#>
[string]$LogFile = Join-Path  "$env:temp" "$(gc env:computername).log"
[string]$stdErrLog = Join-Path "$env:temp" "$(gc env:computername)err.log"
[string]$stdOutLog = Join-Path "$env:temp" "$(gc env:computername)out.log"

Function execInProc {
param(
    [String] $process,
    [String] $arguments
    )
    $app = Start-Process "$process" -ArgumentList "$arguments" -PassThru -RedirectStandardOutput $stdOutLog -RedirectStandardError $stdErrLog
    Wait-Process $app.Id
    Get-Content $stdErrLog, $stdOutLog | Out-File $LogFile -Append
    return $app.ExitCode
}

Function normalizePath {
param(
    [String] $path1,
    [String] $path2
    )
    return Join-Path $path1 $path2
}

Function LogWrite {
param(
    [string] $logstring
    )
    Add-Content $LogFile -value "$(Get-Date -format u):$logstring"
}

Function evaulateResultCode {
param(
	[int] $exitCode,
	[string] $executedProgram
    )
	If($exitCode -ile 1) { #-ile -> $exitCode <= 1
		LogWrite "Installed $executedProgram"
	}
	Else {
		LogWrite "Failed to install $executedProgram"
	}
}

Function Get-EncryptedStringHash
{
  param(
    [String] $String,
    [String]$HashName = "MD5"

  )
  $StringBuilder = New-Object System.Text.StringBuilder
  [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{
  [Void]$StringBuilder.Append($_.ToString("x2"))
  }
  $StringBuilder.ToString()
}

Function Get-MyModule
{
Param([string]$name)
if(-not(Get-Module -name $name))
{
if(Get-Module -ListAvailable |
Where-Object { $_.name -eq $name })
{
Import-Module -Name $name
$true
} #end if module available then import
else { $false } #module not available
} # end if not module
else { $true } #module already loaded
} #end function get-MyModule

Export-ModuleMember -Function execInProc, normalizePath, LogWrite, evaulateResultCode, Get-EncryptedStringHash
