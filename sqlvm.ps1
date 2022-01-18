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
Invoke-WebRequest 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2017.bak' -OutFile 'C:\AdventureWorks2017.bak'

# Download the database backup file from the GitHub repo
Invoke-WebRequest 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak' -OutFile 'C:\WideWorldImporters-Full.bak'

# Download the database backup file from the GitHub repo
Invoke-WebRequest 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImportersDW-Full.bak' -OutFile 'C:\WideWorldImportersDW-Full.bak'


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
#$DatabaseName = 'WideWorldImporters'
$SqlMiUser = 'sqlmiuser'
$PasswordPlainText = 'Password.1234567890'
$PasswordSecure = ConvertTo-SecureString $PasswordPlainText -AsPlainText -Force
$PasswordSecure.MakeReadOnly()
$Creds = New-Object System.Management.Automation.PSCredential $SqlMiUser, $PasswordSecure
$Password = $Creds.GetNetworkCredential().Password

# Restore the WideWorldImporters database using the downloaded backup file




# Restore the WideWorldImporters database using the downloaded backup file
function Restore-SqlDatabase1 {
    $bakFileName = 'C:\AdventureWorks2017.bak'

    $RestoreCmd = "

  RESTORE DATABASE [AdventureWorks2017]
  FILE = N'AdventureWorks2017'
  FROM DISK = N'C:\AdventureWorks2017.bak'
  WITH 
    FILE = 1, NOUNLOAD, STATS = 10,
    MOVE N'AdventureWorks2017'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\AdventureWorks2017.mdf',
    MOVE N'AdventureWorks2017_log'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\AdventureWorks2017_log.ldf'"

    Invoke-SqlCmd -Query $RestoreCmd -QueryTimeout 3600 -Username $SqlMiUser -Password $Password -ServerInstance $ServerName
    Start-Sleep -Seconds 30
}

function Restore-SqlDatabase2 {
    $bakFileName = 'C:\WideWorldImporters-Full.bak'

    $RestoreCmd = "RESTORE DATABASE [WideWorldImporters(OLTP)]
 
  FROM DISK = N'C:\WideWorldImporters-Full.bak'
  WITH 
    FILE = 1, 
    MOVE N'WWI_Primary'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\WideWorldImporters.mdf',
    MOVE N'WWI_UserData'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\WideWorldImporters_UserData.ndf',
    MOVE N'WWI_Log'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\WideWorldImporters_log.ldf',
    MOVE N'WWI_InMemory_Data_1'
   TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\WideWorldImporters_InMemory_Data_1'
    "

    Invoke-SqlCmd -Query $RestoreCmd -QueryTimeout 3600 -Username $SqlMiUser -Password $Password -ServerInstance $ServerName
    Start-Sleep -Seconds 30
}

function Restore-SqlDatabase3 {
    $bakFileName = 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\WideWorldImporters-Standard.bak'

    $RestoreCmd = "RESTORE DATABASE [WideWorldImporters(DW)]
 FROM DISK = N'C:\WideWorldImportersDW-Full.bak'
  WITH 
    FILE = 1, 
    MOVE N'WWI_Primary'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\WideWorldImportersDW.mdf',
	MOVE N'WWI_UserData'
	TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\WideWorldImportersDW_UserData.ndf',
    MOVE N'WWI_Log'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\WideWorldImportersDW_log.ldf',
    MOVE N'WWIDW_InMemory_Data_1'
    TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\WideWorldImportersDW_InMemory_Data_1'
    "

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

