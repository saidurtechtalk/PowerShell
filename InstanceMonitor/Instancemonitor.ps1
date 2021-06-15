
<#
    .DESCRIPTION
    THis script loops through all the servers in a csv file whihc is provided to the script
    as an input and checks the status of SQL services on each of the server. The detailed status
    report is written in a csv file at the same place as input csv file.
    This script monitors follwing three services:-
    SQL SERVER Service
    SQL Agent Service
    SQL Browser Service
    
    .EXAMPLE
    cd C:\Users\user1\documents
    Ublock-File -path C:\users\user1\documents\SQLServiceMonitor.ps1
    ./SQLServiceMonitor.ps1 -csvPath C:\users\user1\documents\input.csv
    This example first sets the powershell location to the folder where ps1 script is placed and then
    it ublocks the ps1 file so that powershell can run this script without changing execution Policy
    and then actual execution of the script starts where the script takes a CSV file placed at 
    C:\users\user1\documents\input.csv and generates an output csv file at 
    C:\users\user1\documents\sqlreport-TIMESTAMP.csv
#>
$csvPath = "$env:USERPROFILE\list.csv"
$props = @()
$logdate = (Get-Date).ToString('MM/dd/yyyy hh:mm:ss')
#Test the server connection

$csvData = Import-Csv -Path $csvPath
foreach ($instance in $csvData) {
    $server = (($instance."Instance Name").split("\"))[0]

    if((test-connection -ComputerName $Server -count 2 -ErrorAction SilentlyContinue)) {
        $instanceName = (($instance."Instance Name").split("\"))[1]
        $service_SQLServer = 'MSSQL$' + $instanceName
        $service_SQLAgent = 'SQLAgent$' + $instanceName
        $service_SQLBrowser = "SQLBrowser"
        #$service_SQLTelemetry = SQLTELEMETRY$ + $instanceName
        $services = @($service_SQLServer,$service_SQLAgent,$service_SQLBrowser)
        $services | ForEach-Object {
            $serviceDetails = Get-Service -ComputerName $server $_
            $props += [PSCustomObject]@{
                Time = $logdate
                ServerName = $server
                ServiceName = $serviceDetails.Name
                DisplayName = $serviceDetails.DisplayName
                Status = $serviceDetails.Status
                ServiceType = $serviceDetails.ServiceType
            }
        }
    }
    else {
        $props += [PSCustomObject]@{
            Time = $logdate
            ServerName = $server
            ServiceName = "Server Unreachable"
            DisplayName = "Server Unreachable"
            Status = "Server Unreachable"
            ServiceType = "Server Unreachable"
        }
    }

}
$outPath = (Split-Path $csvPath -Parent) + "\sqlreport-" + (Get-date $logdate -Format "hhmm_ddMMyyyy") + ".csv"
$props | Where-Object {$_.Status -ne "Running"} | Export-Csv -Path $outPath -NoTypeInformation

