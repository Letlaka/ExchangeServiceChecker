# Prompt for admin credentials
$credential = Get-Credential -Message "Please enter your admin credentials"

# Read server list from text file
$Servers = Get-Content -Path ".\Servers.txt"

# Initialize arrays to store services that were not running and errors that occurred
$AllServicesNotRunning = @()
$ErrorList = @()

# Loop through each server in the list
foreach ($Server in $Servers) {
    $ServicesNotRunning = @()
    # Check if server is online by pinging it
    if (Test-Connection -ComputerName $Server -Count 1 -Quiet) {
        Write-Host "$Server is online"
        # Try to get a list of Exchange services on the server
        try {
            $Services = Invoke-Command -ComputerName $Server -ScriptBlock { Get-Service | Where-Object { $_.DisplayName -like "*Exchange*" } } -Credential $credential -ErrorAction Stop
        }
        catch {
            # If an error occurs, add it to the error list and skip to the next server
            $ErrorList += New-Object PSObject -Property @{
                Server = $Server
                Error  = $_.Exception.Message
            }
            continue
        }
        # Loop through each service in the list
        foreach ($Service in $Services) {
            # Check if the service is not running
            if ($Service.Status -ne "Running") {
                Write-Host "$($Service.DisplayName) on $Server is not running"
                # Add the service to the list of services that were not running
                $ServicesNotRunning += New-Object PSObject -Property @{
                    Server        = $Server
                    Service       = $Service.DisplayName
                    PreviousState = $Service.Status
                }
                # Try to start the service
                try {
                    Invoke-Command -ComputerName $Server -ScriptBlock { param($ServiceName) Start-Service -Name $ServiceName } -ArgumentList $Service.Name -Credential $credential -ErrorAction Stop
                }
                catch {
                    # If an error occurs, add it to the error list
                    $ErrorList += New-Object PSObject -Property @{
                        Server = $Server
                        Error  = $_.Exception.Message
                    }
                }
            }
        }
    }
    else {
        Write-Host "$Server is offline"
    }
    # Check if any services were not running on this server
    if ($ServicesNotRunning) {
        # Loop through each service that was not running and get its current status
        foreach ($Service in $ServicesNotRunning) {
            try {
                $CurrentStatus = Invoke-Command -ComputerName $Server -ScriptBlock { param($ServiceName) (Get-Service -Name $ServiceName).Status } -ArgumentList $Service.Service -Credential $credential -ErrorAction Stop
                Add-Member -InputObject $Service -MemberType NoteProperty -Name CurrentState -Value $CurrentStatus
            }
            catch {
                # If an error occurs, add it to the error list
                $ErrorList += New-Object PSObject -Property @{
                    Server = $Server
                    Error  = $_.Exception.Message
                }
            }
        }
        # Add the services that were not running on this server to the master list of all services that were not running across all servers
        $AllServicesNotRunning += $ServicesNotRunning
    }
}
# Check if any services were not running across all servers
if ($AllServicesNotRunning) {
    Write-Host "`nSummary of services that were not running and have been started:"
    # Loop through each server and display a table of services that were not running and have been started on that server
    foreach ($Server in ($AllServicesNotRunning.Server | Sort-Object | Get-Unique)) {
        Write-Host "`n${Server}:"
        ($AllServicesNotRunning | Where-Object { $_.Server -eq $Server }) | Format-Table -AutoSize -Property Service, PreviousState, CurrentState
    }
}
# Check if any errors occurred during script execution
if ($ErrorList) {
    Write-Host "`nErrors encountered during script execution:"
    # Loop through each server and display a table of errors that occurred on that server
    foreach ($Server in ($ErrorList.Server | Sort-Object | Get-Unique)) {
        Write-Host "`n${Server}:"
        ($ErrorList | Where-Object { $_.Server -eq $Server }) | Format-Table -AutoSize -Property Error
    }
}
