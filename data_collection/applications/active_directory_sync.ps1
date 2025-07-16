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
            NextSyncType = $sync_schedule.NextSyncCyclePolicyType
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
# SIG # Begin signature block
# MIIFlQYJKoZIhvcNAQcCoIIFhjCCBYICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDDb+pB8cEB2/Zv
# /gHeLgQ4zky8B8fkmEHBnfepTTUEaaCCAwowggMGMIIB7qADAgECAhAoyEyARsZY
# mksZuPjiDe0aMA0GCSqGSIb3DQEBCwUAMBsxGTAXBgNVBAMMEElUUyBDb2RlIFNp
# Z25pbmcwHhcNMjUwMzA1MjMyNzU3WhcNMjYwMzA1MjM0NzU3WjAbMRkwFwYDVQQD
# DBBJVFMgQ29kZSBTaWduaW5nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEA0fKohFZ3wtfJOLMaO/4VoloNfloWf8B5UjaE2sm9EQpLpP8/hTHqspXgz7zS
# 7euCCxH97qt1kk9l3RpxbEcs1xcWnCrZryFO2F8Bvmyhtk5tE30DSREwssUwOaZL
# McCKPEb2YerdOIUoiPdwn+nx98PLmzoNM2A25KIAmsmOUX/4TxH70GYPR8YxdrMI
# 7mYFDMneJVZ7B9QL0JpCC9oAyR5L1a6yg4amHK9y44YWzm6yfqrzrmJlEw/I/hLc
# pDEqZ6ohfcCdXQF4HoJx2ecusdZTE7IktgF/GJmkIfCtu6BlHZUhCoT9hksucI9z
# sw90bbeyna4cxlbcL9FlgRwBkQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYD
# VR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFP5GbQt+h0IBzqiQbJsxiRB+gKmT
# MA0GCSqGSIb3DQEBCwUAA4IBAQCSYypjyMC6zh5P/OpsJw7JQIuSYtyL3/7ZymE4
# bC4OEkN7ScdQFJyD2Yb88exHgjziVNZK0g7gnc9cwExDFfibDNWWWpzp91fcGBqa
# FFh0PNFb3xuXB/HOGNXGxN4TixK95PiaxQtkG/abdw82kGcCbD6GcMYcPCr4XYqs
# mASG226FdraG5BmasUmUScRlKvoUACOaa65aOlMKGSuf36wbmSA+V/rxmzQnS0Vp
# 03VpVrHqa6uh3t5oM9zbyjf8+oysqT3BotZrkZtX6lfVFNHTympfYxf67bDQ3Pw2
# iJ/MpHh+AQRZFQfWc9DWv7I2TdPLGvaBcAdcuvcXN+iLErPqMYIB4TCCAd0CAQEw
# LzAbMRkwFwYDVQQDDBBJVFMgQ29kZSBTaWduaW5nAhAoyEyARsZYmksZuPjiDe0a
# MA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwLwYJKoZIhvcNAQkEMSIEIJbn64rcgG5jcqOn8kfvbF1wIHKMt+8LMnKS
# lPnxzYDGMA0GCSqGSIb3DQEBAQUABIIBAJllvAYhejF1K6VJb1J2SQx2DFQT57if
# O1HHNbdgyVcuhIrrTIFwOn5C2WlCqKySISGi/24tdRw66/+suz41NRbbpqIHy6Pd
# HLJKybTLrsC8IbZ6nXy58Jo6eNa+Uo3uhIoqHb+XtVZTWAJuFFy1jok205nYa6Vp
# DoDlmpBEAelutcupilkFxIPzJIA5Ja3I9XWKL4acdH/heKmmS0WYvqhiYa1rYRBS
# pH7WMwox4vbwjF646ZkzFZCeQPX4MyHPlq5cWMGShWtaaUjPcO00y5r98ZR+dv7y
# VgO0YT+FDIPXIWxkl8pVj/6yywbIDK5VaWE5weWyRUP6u/UKfE5SO+8=
# SIG # End signature block
