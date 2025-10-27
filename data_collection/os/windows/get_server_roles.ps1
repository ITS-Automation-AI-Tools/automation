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


    $base_obj = [pscustomobject]@{
        device_name = $hostname
        agent_id = $agent_id.agent_id
        id_type = $agent_id.id_type
        serial_number = $serial_number
    }


    ForEach($role in $installed_features | ?{$_.Installed} ){
        $base_obj.psobject.Properties | %{Add-Member -InputObject $role -MemberType NoteProperty -Name $_.Name -Value $_.Value -Force }
    }




    $output = [pscustomobject]@{
        status = "succeeded"
        message = $null
        result = ($installed_features | ?{$_.Installed} | Select device_name, `
                                                                agent_id, `
                                                                id_type, `
                                                                serial_number, `
                                                                @{name="role_name"; expression={$_.name}}, `
                                                                @{name="role_display_name"; expression={$_.DisplayName}}, `
                                                                @{name="role_description"; expression={$_.Description}}, `
                                                                @{name="role_type"; expression={$_.FeatureType}}, `
                                                                @{name="role_status"; expression={$_.InstallState}}, `
                                                                @{name="role_installed"; expression={$_.Installed}} 
                )
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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCJ+F5r4VdhKl/e
# EYJ4bsDg6X1VWgeEtZNmBJwsx1eecqCCAwowggMGMIIB7qADAgECAhAoyEyARsZY
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
# gjcCARUwLwYJKoZIhvcNAQkEMSIEILwEuO5hbh3pB/5Pxt2mc3hYU8VZQcOOXgkO
# DXoElgbPMA0GCSqGSIb3DQEBAQUABIIBAGKmeB3/HtnklyYCuuw/2d7XEIZZ3qOB
# gtulMG6mQ1+wcykL2UmpdjebfVatD9JA9IbWHoPZqfhZAd7tHImPqXvJ18zLV5th
# /s+VO2VjwAF0spLjfYtPVrUckG9ENbr20TC9lwI2cqF3hoBaSyllziihK3/dDkLh
# rudyZuaEUHbQVrAAhTkdiZ+tIrAEhVbAGekicr7typy0EExjtzu/49bxFjM2iGVF
# 4rwsspL9Q8Yj1YGQHXTX9ks1zkDGW9RyEFamidZuWwNBAhZl7qlcX/fVjk8tw9q7
# UapilSDop7iQgRzGL4rOVNLfo7sagPulHUo9tqo3ltQpfucW6h1dnyM=
# SIG # End signature block
