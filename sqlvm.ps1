Param (
    [Parameter(Mandatory = $true)]
    [string]
    $AzureUserName,

    [string]
    $AzurePassword,

    [string]
    $AzureTenantID,

    [string]
    $AzureSubscriptionID,

    [string]
    $ODLID,

    [string]
    $DeploymentID,

    [string]
    $InstallCloudLabsShadow,

    [string]
    $SPDisplayName,

    [string]
    $SPID,

    [string]
    $SPObjectID,

    [string]
    $SPSecretKey,

    [string]
    $AzureTenantDomainName,

    [Parameter(Mandatory=$False)] [string] $SqlPass = ""

)

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "Tls, Tls11, Tls12, Ssl3"

# Enable SQL Server ports on the Windows firewall
function Add-SqlFirewallRule {
    $fwPolicy = $null
    $fwPolicy = New-Object -ComObject HNetCfg.FWPolicy2

    $NewRule = $null
    $NewRule = New-Object -ComObject HNetCfg.FWRule

    $NewRule.Name = "SqlServer"
    # TCP
    $NewRule.Protocol = 6
    $NewRule.LocalPorts = 1433
    $NewRule.Enabled = $True
    $NewRule.Grouping = "SQL Server"
    # ALL
    $NewRule.Profiles = 7
    # ALLOW
    $NewRule.Action = 1
    # Add the new rule
    $fwPolicy.Rules.Add($NewRule)
}

Add-SqlFirewallRule
$SqlPass="Password.1!!"
# Download and install Data Mirgation Assistant
(New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/C/6/3/C63D8695-CEF2-43C3-AF0A-4989507E429B/DataMigrationAssistant.msi', 'C:\DataMigrationAssistant.msi')
Start-Process -file 'C:\DataMigrationAssistant.msi' -arg '/qn /l*v C:\dma_install.txt' -passthru | wait-process

# Attach the downloaded backup files to the local SQL Server instance
function Setup-Sql {
    #Add snap-in
    Add-PSSnapin SqlServerCmdletSnapin* -ErrorAction SilentlyContinue

    $ServerName = "SQL2008-$DeploymentID"
    $DatabaseName = 'PartsUnlimited'
    
    $Cmd = "USE [master] CREATE DATABASE [$DatabaseName]"
    Invoke-Sqlcmd $Cmd -QueryTimeout 3600 -ServerInstance $ServerName

    Invoke-Sqlcmd "ALTER DATABASE [$DatabaseName] SET DISABLE_BROKER;" -QueryTimeout 3600 -ServerInstance $ServerName
    
    Invoke-Sqlcmd "CREATE LOGIN PUWebSite WITH PASSWORD = '$SqlPass';" -QueryTimeout 3600 -ServerInstance $ServerName
    Invoke-Sqlcmd "USE [$DatabaseName];CREATE USER PUWebSite FOR LOGIN [PUWebSite];EXEC sp_addrolemember 'db_owner', 'PUWebSite'; " -QueryTimeout 3600 -ServerInstance $ServerName

    Invoke-Sqlcmd "EXEC sp_addsrvrolemember @loginame = N'PUWebSite', @rolename = N'sysadmin';" -QueryTimeout 3600 -ServerInstance $ServerName

    Invoke-Sqlcmd "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2" -QueryTimeout 3600 -ServerInstance $ServerName

    Restart-Service -Force MSSQLSERVER
    #In case restart failed but service was shut down.
    Start-Service -Name 'MSSQLSERVER' 
}
Setup-Sql

$hostname= "$env:ComputerName"
$path="C:\CloudLabs\Validator\installer.bat"
(Get-Content -Path "$path") | ForEach-Object {$_ -Replace "serverName", "$hostname"} | Set-Content -Path "$path"

Function InstallCloudLabsShadow($odlid, $InstallCloudLabsShadow)
    {
        if($InstallCloudLabsShadow -eq 'yes')
        {
            $WebClient = New-Object System.Net.WebClient
            $url1 = "https://spektrasystems.screenconnect.com/Bin/ConnectWiseControl.ClientSetup.msi?h=instance-ma1weu-relay.screenconnect.com&p=443&k=BgIAAACkAABSU0ExAAgAAAEAAQDhrCYwK%2BhPzyOyTYW71BahP4Q7hsWvkU20udO6d7cGuH8VAADzVNnsk39zavkgVu2uLHR1mfAL%2BUd6iAJOofhlcjO%2FB%2FVAEwvqtQ7403Nqm6rGvy6%2FxHEiqvzvn42JADRxdGVFaw9SYyTi4QckGjG0OnG69mW2RBQdWOZ3FKmhJD6zWRPZVTbl7gJkpIdMZx0BbWKiYVsvJYgoCWNXIqqH77rigu5dsmEnWeC9J0Or1KaU%2Bzsd6QJwAzEwomhiGp3FII4wbGBnCiHLD%2FrtNgR%2BJ1H3bKgYkesdxuFvO5DzUc3eEOVBSwR0crd06J%2BJP4DolgWWNZN6ZmQ1s5aOQgSq&e=Access&y=Guest&t=&c="
            $url3 = "&c=&c=&c=&c=&c=&c=&c="
            $finalurl = $url1 + $odlid + $url3
            $WebClient.DownloadFile("$finalurl","C:\Packages\cloudlabsshadow.msi")
            Start-Process msiexec.exe -Wait '/I C:\Packages\cloudlabsshadow.msi /qn' -Verbose
        }
    }

    InstallCloudLabsShadow $ODLID $InstallCloudLabsShadow
#Import Common Functions
$path = pwd
$path=$path.Path
$commonscriptpath = "$path" + "\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

# Run Imported functions from cloudlabs-windows-functions.ps1
WindowsServerCommon
#InstallCloudLabsShadow $ODLID $InstallCloudLabsShadow
CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID
SPtoAzureCredFiles $SPDisplayName $SPID $SPObjectID $SPSecretKey $AzureTenantDomainName

InstallLegacyVmValidator
