$credential = Get-Credential -Message "Please enter your admin credentials"
$Servers = "Server1", "Server2", "Server3" # List of Exchange servers
$AllServicesNotRunning = @()
$ErrorList = @()
foreach ($Server in $Servers) {
    $ServicesNotRunning = @()
    if (Test-Connection -ComputerName $Server -Count 1 -Quiet) {
        Write-Host "$Server is online"
        try {
            $Services = Invoke-Command -ComputerName $Server -ScriptBlock {Get-Service | Where-Object {$_.DisplayName -like "*Exchange*"}} -Credential $credential -ErrorAction Stop
        } catch {
            $ErrorList += New-Object PSObject -Property @{
                Server = $Server
                Error = $_.Exception.Message
            }
            continue
        }
        foreach ($Service in $Services) {
            if ($Service.Status -ne "Running") {
                Write-Host "$($Service.DisplayName) on $Server is not running"
                $ServicesNotRunning += New-Object PSObject -Property @{
                    Server = $Server
                    Service = $Service.DisplayName
                    PreviousState = $Service.Status
                }
                try {
                    Invoke-Command -ComputerName $Server -ScriptBlock {param($ServiceName) Start-Service -Name $ServiceName} -ArgumentList $Service.Name -Credential $credential -ErrorAction Stop
                } catch {
                    $ErrorList += New-Object PSObject -Property @{
                        Server = $Server
                        Error = $_.Exception.Message
                    }
                }
            }
        }
    } else {
        Write-Host "$Server is offline"
    }
    if ($ServicesNotRunning) {
        foreach ($Service in $ServicesNotRunning) {
            try {
                $CurrentStatus = Invoke-Command -ComputerName $Server -ScriptBlock {param($ServiceName) (Get-Service -Name $ServiceName).Status} -ArgumentList $Service.Service -Credential $credential -ErrorAction Stop
                Add-Member -InputObject $Service -MemberType NoteProperty -Name CurrentState -Value $CurrentStatus
            } catch {
                $ErrorList += New-Object PSObject -Property @{
                    Server = $Server
                    Error = $_.Exception.Message
                }
            }
        }
        $AllServicesNotRunning += $ServicesNotRunning
    }
}
if ($AllServicesNotRunning) {
    Write-Host "`nSummary of services that were not running and have been started:"
    foreach ($Server in ($AllServicesNotRunning.Server | Sort-Object | Get-Unique)) {
        Write-Host "`n${Server}:"
        ($AllServicesNotRunning | Where-Object {$_.Server -eq $Server}) | Format-Table -Property Service, PreviousState, CurrentState
    }
}
if ($ErrorList) {
    Write-Host "`nErrors encountered during script execution:"
    foreach ($Server in ($ErrorList.Server | Sort-Object | Get-Unique)) {
        Write-Host "`n${Server}:"
        ($ErrorList | Where-Object {$_.Server -eq $Server}) | Format-Table -Property Error
    }
}
