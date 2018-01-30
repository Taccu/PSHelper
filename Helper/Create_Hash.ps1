Function Get-FileName($initialDirectory)
{
 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
 Out-Null

 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = "All files (*.*)| *.*"
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
} #end function Get-FileName

# *** Entry Point to Script ***
$Filename = Get-FileName -initialDirectory "$PSScriptRoot"
$Hash = (Get-FileHash -Algorithm "MD5" $Filename).Hash
Write-Host "Hash for $Filename`: $Hash"
Read-Host "Press Enter to close..."
