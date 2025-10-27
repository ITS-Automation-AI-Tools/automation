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

function Get-VsaAgentIds {  
    Process {
        $base_path = @('HKLM:\SOFTWARE\WOW6432Node\Kaseya\Agent\', 'HKLM:\SOFTWARE\Kaseya\Agent') | ?{Test-Path -Path $_}
        $vsa_instances = $base_path | Get-ChildItem -ErrorAction SilentlyContinue
        $vsa_configs = $vsa_instances | Get-ItemProperty
        return $vsa_configs | Select @{Name="agent_id"; Expression={[string]$_.AgentGUID}}, @{Name="machine_id";Expression={$_.MachineID}}, @{Name="server_address"; Expression={$_.ServerAddr}}, @{Name="vsa_instance"; expression={$_.PSPath | Split-Path -Leaf}}, @{Name="id_type"; Expression={"vsa"}}

    }
}

function Get-DattoAgentIds {  
    Process {
        $base_paths = @('HKLM:\SOFTWARE\WOW6432Node\CentraStage', 'HKLM:\SOFTWARE\CentraStage') | ?{Test-Path -Path $_}
        return $base_paths | Get-ItemProperty | Select @{Name="agent_id"; Expression={[string]$_.DeviceID}}, @{Name="server_address"; Expression={$_.Uri}}, @{Name="id_type"; Expression={"datto"}}
    }
}

function Get-VSAXAgentIds {  
    Process {
        $base_path = @('HKLM:\SOFTWARE\WOW6432Node\Kaseya\PC Monitor', 'HKLM:\SOFTWARE\Kaseya\PC Monitor') | ?{Test-Path -Path $_}
        return $base_path | Get-ItemProperty | Select @{Name="agent_id"; Expression={[string]$_.ComputerIdentifier}}, @{Name="server_address"; Expression={$_.CustomServerAddress}}, @{Name="id_type"; Expression={"vsa_x"}}
    }
}

function Get-LabtechAgentIds {  
    Process {
        $base_path = @('HKLM:\SOFTWARE\WOW6432Node\LabTech\Service', 'HKLM:\SOFTWARE\LabTech\Service') | ?{Test-Path -Path $_}
        return $base_path | Get-ItemProperty | Select @{Name="agent_id"; Expression={[string]$_.ID}}, @{Name="server_address"; Expression={$_.'Server Address'}}, @{Name="id_type"; Expression={"labtech"}}
    }
}

function Get-AgentId {
    Process {
        $agent_ids = @(
            Get-VsaAgentIds
            Get-DattoAgentIds
            Get-VSAXAgentIds
            Get-LabtechAgentIds
        )

        return $agent_ids | Select -First 1
    }
}

$ErrorActionPreference = "STOP"


try{
    $serial_number = (Get-WmiObject Win32_BIOS).SerialNumber
    $hostname = Get-Hostname
    $installed_features = Get-WindowsFeature
    $agent_id = Get-AgentId


    $state = [pscustomobject]@{
        name = $hostname
        agent_id = $agent_id.agent_id
        id_type = $agent_id.id_type
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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD1QkuOQzwGC4bh
# U+RrV+IBGP4Ks+kedX2wXkQ+ERf8yKCCAwowggMGMIIB7qADAgECAhAoyEyARsZY
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
# gjcCARUwLwYJKoZIhvcNAQkEMSIEIBB45sLzA9Ewyc7MY4opdiv19/XCe8+HJzwl
# KVX45T1sMA0GCSqGSIb3DQEBAQUABIIBAGHpU2FdWm2czHX3zH+y4eJLGNzAXXmc
# nUbGzUSh5AYjAZzK9dB31sfpeso3o+H5bUmqRjiNng8nc4JrlLOlxDqZTjxqMW69
# D9hhVCC6aqWJCmrgKHW5A38OA8Dgis/GUiczpn5TlOXSzfznmMPJi3AbF2XgN3LP
# BX63NfrE3uVtexn/nRtrscys2JiGWIFIy1nRBkqk8F9IPboqftT2YEnchqdTLVni
# 0XVMOCYMjejC8oLV2PnNrF0Pw7xzwlD8zGd/Wc/dw4oHWo1gHCpMd4sJYiiNWK8z
# kmaix0fyobkOkSXqBNi43sJa/C0Od/ypgw0a5r553rmyNIBbivqdrQY=
# SIG # End signature block
