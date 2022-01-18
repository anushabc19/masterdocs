# Disable Internet Explorer Enhanced Security Configuration
function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force
    Write-Host 'IE Enhanced Security Configuration (ESC) has been disabled.' -ForegroundColor Green
}

# Force TLS 1.2 use instead of TLS 1.0
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Disable IE ESC
Disable-InternetExplorerESC

# Download the database backup file from the GitHub repo
Invoke-WebRequest 'https://raw.githubusercontent.com/microsoft/MCW-Migrating-SQL-databases-to-Azure/master/Hands-on%20lab/lab-files/Database/WideWorldImporters.bak' -OutFile 'C:\WideWorldImporters.bak'

# Download and install Data Mirgation Assistant
# Invoke-WebRequest 'https://download.microsoft.com/download/C/6/3/C63D8695-CEF2-43C3-AF0A-4989507E429B/DataMigrationAssistant.msi' -OutFile 'C:\DataMigrationAssistant.msi'
# Start-Process -file 'C:\DataMigrationAssistant.msi' -arg '/qn /l*v C:\dma_install.txt' -passthru | wait-process

# Wait a few minutes to allow the SQL Resource provider setup to start
Start-Sleep -Seconds 240.0

# Add snapins to allow use of the Invoke-SqlCmd commandlet
Add-PSSnapin SqlServerProviderSnapin100 -ErrorAction SilentlyContinue
Add-PSSnapin SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue

# Define database variables
$ServerName = $env:ComputerName
$DatabaseName = 'WideWorldImporters'
$SqlMiUser = 'sqlmiuser'
$PasswordPlainText = 'Password.1234567890'
$PasswordSecure = ConvertTo-SecureString $PasswordPlainText -AsPlainText -Force
$PasswordSecure.MakeReadOnly()
$Creds = New-Object System.Management.Automation.PSCredential $SqlMiUser, $PasswordSecure
$Password = $Creds.GetNetworkCredential().Password

# Restore the WideWorldImporters database using the downloaded backup file
function Restore-SqlDatabase {
    $bakFileName = 'C:\' + $DatabaseName +'.bak'

    $RestoreCmd = "USE [master];
                   GO
                   RESTORE DATABASE [$DatabaseName] FROM DISK ='$bakFileName' WITH REPLACE;
                   GO"

    Invoke-SqlCmd -Query $RestoreCmd -QueryTimeout 3600 -Username $SqlMiUser -Password $Password -ServerInstance $ServerName
    Start-Sleep -Seconds 30
}

function Enable-ServiceBroker {
    $SetBrokerCmd = "USE [$DatabaseName];
                     GO
                     GRANT ALTER ON DATABASE:: $DatabaseName TO $SqlMiUser;
                     GO
                     ALTER DATABASE [$DatabaseName]
                     SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE;
                     GO"

    Invoke-SqlCmd -Query $SetBrokerCmd -QueryTimeout 3600 -Username $SqlMiUser -Password $Password -ServerInstance $ServerName
}

# Restore the WideWorldImporters database using the downloaded backup file
function Restore-SqlDatabase1 {
    $bakFileName = 'C:\AdventureWorks2017.bak'

    $RestoreCmd = "

 RESTORE DATABASE [AdventureWorks2017]
  FILE = N'AdventureWorks2017'
  FROM DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\AdventureWorks2017.bak'
  WITH 
    FILE = 1, NOUNLOAD, STATS = 10,
    MOVE N'AdventureWorks2017'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\AdventureWorks2017.mdf',
    MOVE N'AdventureWorks2017_log'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\AdventureWorks2017_log.ldf'

	    
"

    Invoke-SqlCmd -Query $RestoreCmd -QueryTimeout 3600 -Username $SqlMiUser -Password $Password -ServerInstance $ServerName
    Start-Sleep -Seconds 30
}

function Restore-SqlDatabase2 {
    $bakFileName = 'C:\WideWorldImporters-Standard.bak'

    $RestoreCmd = "RESTORE DATABASE [WideWorldImporters(OLTP)]
 
  FROM DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\WideWorldImporters-Standard.bak'
  WITH 
    FILE = 1, 
    MOVE N'WWI_Primary'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\WideWorldImporters.mdf',
    MOVE N'WWI_UserData'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\WideWorldImporters_UserData.ndf',
    MOVE N'WWI_Log'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\WideWorldImporters_log.ldf',
    MOVE N'WWI_InMemory_Data_1'
   TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\WideWorldImportersDW_InMemory_Data_1'
    "

    Invoke-SqlCmd -Query $RestoreCmd -QueryTimeout 3600 -Username $SqlMiUser -Password $Password -ServerInstance $ServerName
    Start-Sleep -Seconds 30
}

function Restore-SqlDatabase3 {
    $bakFileName = 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\WideWorldImporters-Standard.bak'

    $RestoreCmd = "RESTORE DATABASE [WideWorldImporters(DW)]
 FROM DISK = N'C:\WideWorldImportersDW-Standard.bak'
  WITH 
    FILE = 1, 
    MOVE N'WWI_Primary'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\WideWorldImportersDW.mdf',
	MOVE N'WWI_UserData'
	TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\WideWorldImportersDW_UserData.ndf',
    MOVE N'WWI_Log'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\WideWorldImportersDW_log.ldf'"

    Invoke-SqlCmd -Query $RestoreCmd -QueryTimeout 3600 -Username $SqlMiUser -Password $Password -ServerInstance $ServerName
    Start-Sleep -Seconds 30
}

# Restore the Adventuerworks datasbase
Restore-SqlDatabase1

Start-Sleep -Seconds 30

# Restore the WideWorldImporters (OLTP)  datasbase
Restore-SqlDatabase2

Start-Sleep -Seconds 30

# Restore the WideWorldImporters (DW)  datasbase
Restore-SqlDatabase3

Start-Sleep -Seconds 30

# Restart the MSSQLSERVER service.
Stop-Service -Name 'MSSQLSERVER' -Force
Start-Service -Name 'MSSQLSERVER'

# Enable the Service Broker functionality on the database
Enable-ServiceBroker


