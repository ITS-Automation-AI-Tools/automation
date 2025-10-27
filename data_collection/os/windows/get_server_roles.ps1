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


