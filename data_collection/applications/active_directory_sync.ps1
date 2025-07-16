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
            CreatedAt = $connector.CreationTime
            UpdatedAt = $connector.LastModificationTime
            ObjectInclusionList = $connector.ObjectInclusionList

            SyncIntervalMinutes = $sync_schedule.AllowedSyncCycleInterval.TotalMinutes
            SyncIntervalSeconds = $sync_schedule.AllowedSyncCycleInterval.TotalSeconds
            NextSyncType = $sync_schedule.NextSyncCyclePolicyType
            NextSyncTime = $sync_schedule.NextSyncCycleStartTimeInUTC
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