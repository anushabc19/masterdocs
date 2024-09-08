Param (
)

function Install-Chrome {
    param (
        [string]$DownloadUrl = "https://dl.google.com/chrome/install/latest/chrome_installer.exe",
        [string]$InstallerPath = "$env:TEMP\chrome_installer.exe"
    )

    # Download the Chrome installer
    Write-Host "Downloading Google Chrome installer..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath

    # Check if the installer was downloaded successfully
    if (Test-Path $InstallerPath) {
        Write-Host "Installer downloaded successfully."

        # Run the installer
        Write-Host "Installing Google Chrome..."
        Start-Process -FilePath $InstallerPath -Args "/silent /install" -Wait

        # Clean up the installer file
        Remove-Item -Path $InstallerPath

        Write-Host "Google Chrome has been installed successfully."
    } else {
        Write-Host "Failed to download the installer."
    }
}

# Call the function to install Chrome
Install-Chrome

Restart-Computer -Force 
