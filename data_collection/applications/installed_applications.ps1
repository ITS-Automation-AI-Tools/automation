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
        return $vsa_configs | Select @{Name="agent_id"; Expression={$_.AgentGUID}}, @{Name="machine_id";Expression={$_.MachineID}}, @{Name="server_address"; Expression={$_.ServerAddr}}, @{Name="vsa_instance"; expression={$_.PSPath | Split-Path -Leaf}}, @{Name="id_type"; Expression={"vsa"}}

    }
}

function Get-DattoAgentIds {  
    Process {
        $base_paths = @('HKLM:\SOFTWARE\WOW6432Node\CentraStage', 'HKLM:\SOFTWARE\CentraStage') | ?{Test-Path -Path $_}
        return $base_paths | Get-ItemProperty | Select @{Name="agent_id"; Expression={$_.DeviceID}}, @{Name="server_address"; Expression={$_.Uri}}, @{Name="id_type"; Expression={"datto"}}
    }
}

function Get-VSAXAgentIds {  
    Process {
        $base_path = @('HKLM:\SOFTWARE\WOW6432Node\Kaseya\PC Monitor', 'HKLM:\SOFTWARE\Kaseya\PC Monitor') | ?{Test-Path -Path $_}
        return $base_path | Get-ItemProperty | Select @{Name="agent_id"; Expression={$_.ComputerIdentifier}}, @{Name="server_address"; Expression={$_.CustomServerAddress}}, @{Name="id_type"; Expression={"vsa_x"}}
    }
}

function Get-LabtechAgentIds {  
    Process {
        $base_path = @('HKLM:\SOFTWARE\WOW6432Node\LabTech\Service', 'HKLM:\SOFTWARE\LabTech\Service') | ?{Test-Path -Path $_}
        return $base_path | Get-ItemProperty | Select @{Name="agent_id"; Expression={$_.ID}}, @{Name="server_address"; Expression={$_.'Server Address'}}, @{Name="id_type"; Expression={"labtech"}}
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
