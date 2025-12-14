<#
.SYNOPSIS
Retrieves the enhanced datapath flow table statistics for all ESXi hosts managed by NSX.

.LINK
https://www.bernardsmith.net/posts/2025-05-27-nsx-ens-flowtable-alarms/

.PARAMETER NsxFqdn
Specifies the FQDN of the NSX server. Should be the NSX cluster's VIP.

.PARAMETER AdminCreds
Specifies the admin credentials used to log into NSX. By default, it prompts the user for credentials upon execution.

.EXAMPLE
# All Systems
./Get-NsxFlowTableStatistics.ps1 -NsxFqdn nsx.sddc.lab | Format-Table

.EXAMPLE
# Windows Only
./Get-NsxFlowTableStatistics.ps1 -NsxFqdn nsx.sddc.lab | Out-GridView
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $NsxFqdn,
    [System.Management.Automation.PSCredential] $AdminCreds = (Get-Credential -Message "Enter your NSX admin credentials")
)

# Login to NSX Manager
Connect-NsxServer -Server $NsxFqdn -Credential $adminCreds | Out-Null

# Retrieve all host nodes in this NSX Manager
$hostNodes = (Invoke-ListHostTransportNodes -SiteId default -EnforcementpointId default).Results

# Retrieve flow table statistics for each host
$fpStats = foreach ($hostNode in $hostNodes) {
    # Retrieve flow table statistics from NSX Manager for this host
    $stats = Invoke-GetObservabilityMonitorStatics -SiteId default -EnforcementpointId default -HostTransportNodeId $hostNode.Id -Type fast_path_sys_stats
    # Add the host's name this the output
    $stats.FastPathSysStats.HostEnhancedFastpath | Add-Member -NotePropertyName "Host" -NotePropertyValue $hostNode.DisplayName
    # Output the statistics
    $stats.FastPathSysStats.HostEnhancedFastpath 
}

return $fpStats