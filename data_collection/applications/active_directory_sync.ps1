$ErrorActionPreference = "STOP"
try {
    Import-Module ADSync
        
    $connectors = Get-ADSyncConnector | ?{$_.ConnectorTypeName -eq 'AD'}
    $sync_schedule = Get-ADSyncScheduler
    $data = @()
    ForEach($connector in $connectors){
        $data += [pscustomobject] @{
            ComputerName = (Get-CimInstance Win32_ComputerSystem).Name
                                
            ConnectorType = $connector.ConnectorTypeName
            Identifier = $connector.Identifier
            Version = $connector.Version
            Name = $connector.Name
            CreatedAt = (Get-Date $connector.CreationTime).ToUniversalTime().ToString("o")
            UpdatedAt = (Get-Date $connector.LastModificationTime).ToUniversalTime().ToString("o")
            ObjectInclusionList = $connector.ObjectInclusionList

            SyncIntervalMinutes = $sync_schedule.AllowedSyncCycleInterval.TotalMinutes
            SyncIntervalSeconds = $sync_schedule.AllowedSyncCycleInterval.TotalSeconds
            NextSyncType = (Get-Date $sync_schedule.NextSyncCyclePolicyType).ToUniversalTime().ToString("o")
            NextSyncTime = (Get-Date $sync_schedule.NextSyncCycleStartTimeInUTC).ToString("o")
            SyncEnabled = $sync_schedule.SyncCycleEnabled
            SyncMaintenanceEnable = $sync_schedule.MaintenanceEnabled
            SchedulerSuspended = $sync_schedule.SchedulerSuspended
        }             
    }


    $output = [pscustomobject]@{
        status = "succeeded"
        result = $data
    }


} catch {
    $output = [pscustomobject]@{
        message = $_.exception.message
        status = "failed"
        result = $null
    }
}

$output