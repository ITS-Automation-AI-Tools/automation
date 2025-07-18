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
    }

    $installed_features | %{ Add-Member -InputObject $state -MemberType NoteProperty -Name ([string]$_.Name).ToLower() -Value $_.Installed -Force}

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

