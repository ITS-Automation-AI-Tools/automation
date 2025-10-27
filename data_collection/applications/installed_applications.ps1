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

function Get-MD5Hash {
    param(
        [parameter(ValueFromPipeline=$True)][String] $String
    )

    Process {

        $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
        $utf8 = New-Object -TypeName System.Text.UTF8Encoding
        $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($String)))

        return $hash -replace '-', ''
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

function Get-WindowsInstalledApplications {
    Process {
        $agent_id = @(
            Get-VsaAgentIds
            Get-DattoAgentIds
            Get-VSAXAgentIds 
            Get-LabtechAgentIds 
        ) | Select -First 1
        $installs = @()
        $products = Get-Package -AllVersions
        $products = $Products | ?{$_.ProviderName -in @("Programs", "msi")}

        ForEach($product in $products){
            if($product.ProviderName -eq 'msi'){
                try{
                    $item = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($Product.FastPackageReference)" -ErrorAction Stop
                } catch{ 
                    try {
                        $item = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$($Product.FastPackageReference)" -ErrorAction Stop
                    } catch{$item = $null}
                }        
            }
            else {
                $parts = $product.FastPackageReference -split "\\"

                if($parts[0] -eq "hklm32"){
                    $item = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\$($parts[3..$parts.Length] -join "\")"
                }
                elseif($parts[0] -eq "hklm64"){
                    $item = Get-ItemProperty -Path "HKLM:\$($parts[2..$parts.Length] -join "\")"
                }
            }

            if($item -and $item.InstallDate){            
                if($item.InstallDate.Length -eq 8){
                    $year = $item.InstallDate.Substring(0,4)
                    $month = $item.InstallDate.Substring(4,2)
                    $day = $item.InstallDate.Substring(6,2)

                }
                $install_date = "$($month)/$($day)/$($year)"
            } else{
                $install_date = $item.InstallDate
            }




            $metadata = @{}
            For($i = 0; $i -lt $product.Metadata.Count; $i++){
                $metadata.Add($product.Metadata.Keys.LocalName[$i], $product.Metadata.Values[$i])
            }

            $installs += [pscustomobject]@{
                id = ("$($product.CanonicalId)_$($agent_id.agent_id)" | Get-MD5Hash)

                agent_id = $agent_id.agent_id
                id_type = $agent_id.id_type
                device_name = Get-Hostname

                name = $product.Name
                version = $product.Version
                status = $product.Status

                publisher = $metadata.Publisher
                uninstall_string = $metadata.UninstallString
                quiet_uninstall_string = $metadata.QuietUninstallString

                provider = $product.ProviderName
                reference = $product.FastPackageReference

                install_date = $install_date
                comments = $item.Comments
            }
        }

        return $Installs
    }
}



$ErrorActionPreference = "STOP"

try{
    $installed_applications = Get-WindowsInstalledApplications
    $output = [pscustomobject]@{
        status = "succeeded"
        message = $null
        result = $installed_applications
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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAcQP7eHkvrtpf9
# 0awComYQHhVD685gcrJ7V5Qb+QzChaCCAwowggMGMIIB7qADAgECAhAoyEyARsZY
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
# gjcCARUwLwYJKoZIhvcNAQkEMSIEIHOhEGyxtaKsD7OhQb4X5oaFesCWRBtzFaeZ
# 6gBpIEKrMA0GCSqGSIb3DQEBAQUABIIBAC/ozM5XGn+5ZcVv68CzntWIOvLdMzo0
# KkKtJAqnbXXM1reemR3yAJcKpN9oOw2fBUuLSIFF8oSOSNia56pQtjDDP28AtN0W
# hnBJ2UpCGFEuuT2bBgxflGit7ZWW6ULmRJVWQrBSOvq3ujSbg2GNt6ZCZ1rEdmR1
# ai7dc48/Kaw/Wn1wOWEB1Yrfyc2vU67iC4B7wWIyhlghOAgL4ZCM2ZUh+vvMwj0+
# pdMQPjL6bDa0DKTT3pD1pwWk7+xeL16IgBEFM2YTBcGjHXy1wet22htmIIsg4IHk
# WSXpDd/UWJyPFHnCzJ2ZcK23MVWkoHViZMIG0PpI8wncx9PRQr0sPAI=
# SIG # End signature block
