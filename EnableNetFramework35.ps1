$KFolder = "c:\KInstallers"
$LogFilePath = Join-Path -Path $KFolder -ChildPath 'Install.log'

function Log ([string] $Content) {	
    $FormattedLog = "[{0}] - {1}" -f $(Get-Date -Format o), $Content
    Write-Output $FormattedLog
    Add-Content -Path $LogFilePath -Value $FormattedLog -Force
}

# -----------------------------------------------------------------------
#  1, Create folder for config file and installers if not exists
# -----------------------------------------------------------------------
if (-not (Test-Path -Path $KFolder)) {
    Write-Output "Created temp folder $KFolder."
    New-Item -ItemType Directory -Path $KFolder -Force	
}


# -----------------------------------------------------------------------
#  2, Create log file if not exists
# -----------------------------------------------------------------------
if (-not (Test-Path $LogFilePath)) {
    Write-Output "Created log file $LogFilePath."
    New-Item -ItemType File -Path $LogFilePath -Force	
    Add-Content -Path $LogFilePath -Value '-------------------------------------------------------' -Force
    Add-Content -Path $LogFilePath -Value '                          Log                          ' -Force
    Add-Content -Path $LogFilePath -Value '-------------------------------------------------------' -Force
}

Log -Content "Start installation of .net framework 3.5..............................."
$FeatureRequired = Get-ChildItem -Path 'HKLM:\\SOFTWARE\\Microsoft\\NET Framework Setup\\NDP' | Where-Object { $_.PSChildName -eq 'v3.5' }
$FeatureRequired
if ($null -eq $FeatureRequired) {
    Log -Content  "Enabling Windows feature .NetFramework3.5 ..."
    Add-WindowsCapability –Online -Name 'etFx3~~~~' 
    Log -Content  ".NetFramework3.5 enabled."
}
Log -Content "End installation of .net framework 3.5...............................`n`n"
