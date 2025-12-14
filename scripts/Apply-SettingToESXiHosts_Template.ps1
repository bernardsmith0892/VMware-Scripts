<#
.SYNOPSIS
A template script to run a command on multiple ESXi hosts.

.PARAMETER VmHosts
Specifies the ESXi hosts to run the command on.

.EXAMPLE
Connect-VIServer -Server vcenter.sddc.lab
Get-VMHost | ./Apply-SettingToESXiHosts_Template.ps1

.EXAMPLE
Connect-VIServer -Server vcenter.sddc.lab
$vmHosts = Get-VMHost
./Apply-SettingToESXiHosts_Template.ps1 -VmHosts $vmHosts
#>

param (
    [Parameter(ValueFromPipeline)]
    [PSObject[]] $VmHosts
)

# ***********************************************************************************
# * Use this script as a template when you need to apply a setting to multiple ESXi *
# * hosts that requires putting them into maintenance mode and then rebooting them  *
# ***********************************************************************************

begin {
    $InformationPreference = 'Continue'
}

process {
    # Remove this line when the script is complete
    exit

    foreach ($vmHost in $vmHosts) {
        Write-Information "****$('*' * $vmHost.Name.Length)****"
        Write-Information "*** $($vmHost.Name) ***"
        Write-Information "****$('*' * $vmHost.Name.Length)****"

        # Put the host in maintenance mode
        Write-Information "  Putting $($vmHost.Name) into Maintenance Mode..."
        Set-VMHost -State Maintenance -VMHost $vmHost -VsanDataMigrationMode EnsureAccessibility

        # *************************
        # * PUT YOUR CODE IN HERE *
        # *************************

        # Restart the host
        Write-Information "  Restarting $($vmHost.Name)..."
        Restart-VMHost -VMHost $vmHost -Reason "Restarting host because **INSERT YOUR REASON HERE**" -Confirm:$false

        # Wait for host to come back online
        Write-Information "  Waiting for $($vmHost.Name) to come back online..."
        Start-Sleep -Seconds 300 
        do {
            Start-Sleep -Seconds 15
            $vmHostStatus = Get-VMHost -Name $vmHost.Name
        } while ($vmHostStatus.ConnectionState -notlike "Maintenance")

        # Take the host out of maintenance mode
        Write-Information "  Taking $($vmHost.Name) out of Maintenance Mode..."
        Set-VMHost -State Connected -VMHost $vmHost

        Start-Sleep -Seconds 30
    }
}
