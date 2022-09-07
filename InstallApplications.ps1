$KFolder = "c:\KInstallers"

$StorageCofig = Get-Content -Path $(Join-Path -Path $KFolder -ChildPath 'StorageAccount.config')
$StorageAccount = $StorageCofig[0].Split(']:')[-1]
$StorageAccountUri = "https://$StorageAccount.file.core.windows.net"
$SASToken = $StorageCofig[1].Split(']:')[-1]
$ConfigPath = $StorageCofig[2].Split(']:')[-1]


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

Log -Content "Start installation of applications..............................."
# ---------------------------------------------------------
#  3, Download config file
# ---------------------------------------------------------
Log -Content "Start downloading config file $($_.Name) ..."
$ConfigFileName = 'InstallesConfig.json'
$ConfigFileSASUrl = "$StorageAccountUri/$($ConfigPath)?$($SASToken)"
	
$ConfigFile = join-path $KFolder $ConfigFileName
Invoke-WebRequest -Uri $ConfigFileSASUrl -OutFile $ConfigFile
Log -Content "Downloading done."

# ---------------------------------------------------------
#  3, Download installers in config file and install
# ---------------------------------------------------------
$Apps = Get-Content -Path $ConfigFile | ConvertFrom-Json
	
foreach ($App in $Apps) {
	Log -Content "Start installation of $($App.Name)"
		
	# Enable required windows features
	foreach ($WinFeature in $($App.WindowsFeatures)) {
		$FeatureRequired = Get-ChildItem -Path $($WinFeature.RegKey) | Where-Object { $_.PSChildName -eq $($WinFeature.VersionRequired) }
		$FeatureRequired
		if ($null -eq $FeatureRequired) {
			Log -Content  "Enabling Windows feature $($WinFeature.Name) ..."
			Add-WindowsCapability –Online -Name $($WinFeature.FeatureName) 
			Log -Content  "$($WinFeature.Name) enabled."
		}
	}

	# Import windows security credicate
	foreach ($Certificate in $($App.Certificates)) {
		Log -Content  "Start dowloading cretificate of $($Certificate.Name)"
		$CerFileName = $Certificate.FileName
		$CerFileSASUrl = "$StorageAccountUri/$($Certificate.Path)?$($SASToken)"			
		$CerFile = join-path $KFolder $CerFileName
		Invoke-WebRequest -Uri $CerFileSASUrl -OutFile $CerFile

		$CerFile
		Test-Path $CerFile
		Log -Content  "Start importing cretificate of $($Certificate.Name)"
		Import-Certificate -FilePath $CerFile -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
		Log -Content  "Cretificate imported."
	}		

	# Installation
	foreach ($Installer in $($App.Installers)) {
		Log -Content  "Start dowloading installer of $($Installer.Name)"			
		$InstallerFileSASUrl = "$StorageAccountUri/$($Installer.Path)?$($SASToken)"			
		$InstallerFile = join-path $KFolder $($Installer.Name)
		Invoke-WebRequest -Uri $InstallerFileSASUrl -OutFile $InstallerFile

		Log -Content  "Start installing $($Installer.Name) ..."
		$ExitCode = (Start-Process -FilePath $InstallerFile -ArgumentList $($Installer.ArgumentList) -Wait -PassThru).ExitCode
		Log -Content  "Installation done with exit code $($ExitCode)."
	}
}

Log -Content "End installation of applications...............................`n`n"
