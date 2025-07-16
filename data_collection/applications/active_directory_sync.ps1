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
# SIG # Begin signature block
# MIIFlQYJKoZIhvcNAQcCoIIFhjCCBYICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDeTu7L2W8SL30t
# YiEdd4ZAgR80uhOV4HwOzICR9NxzLqCCAwowggMGMIIB7qADAgECAhAoyEyARsZY
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
# gjcCARUwLwYJKoZIhvcNAQkEMSIEIIXB5FtX+8D3dNIe25vIgU1n2u7g8NCDi7mJ
# CycBNtuqMA0GCSqGSIb3DQEBAQUABIIBALldFzWQg/H/cma/br1cXgNpurLW6onL
# MiM2J8rJbOfcCL0539NL58WH+FBb2BbcfoNt1PaWJPIp1XqZqhJ7PwDYzmExuOUq
# YsdIIoIJzE+MLlv2Dp0uTqgCMrjrlAl5117EN4JWXPNy4qVDC8D61KQdAu2LgbhF
# HxlzWzpVjUpl4NyNAjNd2Nm4UJPozxvoRGvRbpB2Vtb9lei5ictk/V4GFywOAqjC
# ewuvd2UVJw/dvcQh0Ih0S20a9NyaV/wH/E1wPrbTAzXJ7vKEgI9w/r6QHnpuU4wg
# At/cscGyFVgeTjN4r9CY5xlgWUkKxucfGHbSmMk77Sf5WEoPxmGDUgc=
# SIG # End signature block
