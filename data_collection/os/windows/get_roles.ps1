function Get-Hostname {
    Process {
        try{
            return (&hostname).toUpper()
        } catch{}
        try{
           return (Get-ComputerInfo -Property "CsDNSHostName").CsDNSHostName.toUpper()
        } catch{}
        try{
            return (Get-WmiObject win32_computersystem -Property *).Name.toUpper()
        } catch{}

        return $env:COMPUTERNAME
    }
}

$ErrorActionPreference = "STOP"

try{
    $serial_number = (Get-WmiObject Win32_BIOS).SerialNumber
    $hostname = Get-Hostname
    $installed_features = Get-WindowsFeature

    $state = [pscustomobject]@{
        name = $hostname
        serial_number = $serial_number
        installed_overview = ($installed_features | ?{$_.Installed} | Select -ExpandProperty DisplayName | Sort ) -join ("`n")
    }

    $installed_features | %{ Add-Member -InputObject $state -MemberType NoteProperty -Name ([string]$_.Name -replace '-','_').ToLower() -Value $_.Installed -Force}

    $output = [pscustomobject]@{
        status = "succeeded"
        message = $null
        result = $state
    }

} catch {
    $output = [pscustomobject]@{
        status = "failed"
        message = $_.exception.message
        result = $null
    }
}

$output


# SIG # Begin signature block
# MIIFlQYJKoZIhvcNAQcCoIIFhjCCBYICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAFQm1buQltTrjI
# Hbla8Jt7wU0eFIzw5fWry3eFX6Fr9qCCAwowggMGMIIB7qADAgECAhAoyEyARsZY
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
# gjcCARUwLwYJKoZIhvcNAQkEMSIEIBCcjx6Sq+VxhX2AqLVRN/9nM0+gsXU8caee
# gteHEDA8MA0GCSqGSIb3DQEBAQUABIIBAEnYFu4QWQR7t0gpcJpR9u3YTxwAW9MV
# 5z+V5GDRGZR7DCZHOKet+0GratdWGNAu4hiLtK2EgEPhg137OcXZmQDpNKQ+FSBF
# tqOBd6ygIr3YxQD66cAHxgnIcfQpcmkhZ7AZk7dkXoHQIXU9NV01Up/wTfNRqAjW
# 2Uxn6hXbGsldth483SfChnDLb4bWlWM1kitZuOYNgpr9+1H0WHVCJ05EixmIlH76
# wcTFqo70ZlthFjn/Fe173S0oEwBOkvqSkW15MjjUk9sBVolfL6ugFKjNDtdKC0jd
# VgdOZr7RyBekNU9Gyt+VeMkylBMpFAs9CD5C7YZ+etvB4F2b8REBuIU=
# SIG # End signature block
