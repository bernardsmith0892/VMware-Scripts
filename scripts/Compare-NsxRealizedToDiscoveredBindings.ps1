<#
.SYNOPSIS
Checks for stale realized IP address bindings in an NSX segment port.

.DESCRIPTION
Checks for stale realized IP address bindings in an NSX segment port.
A stale realized IP address could cause VMs to be matched to security groups incorrectly. This could then result in firewall rules not being properly applied to a VM.

.LINK
https://knowledge.broadcom.com/external/article/329047/stale-ips-in-lsp-realized-bindings-with.html

.PARAMETER SegmentId
Specifies the ID of the NSX segment to check ports in.

.PARAMETER AdminCreds
Specifies the admin credentials used to log into NSX. By default, it prompts the user for credentials upon execution.

.PARAMETER NsxFqdn
Specifies the FQDN of the NSX server. Should be the NSX cluster's VIP.

.PARAMETER ShowAll
(Optional) Select if you want to see the checks for all segment ports, including ports where the discovered and realized bindings match. (Default = False)

.PARAMETER OnlyIpv4
(Optional) Select if you only want to check for IPv4 address bindings. All IPv6 addresses will be ignored. (Default = False)

.PARAMETER IgnoreEmptyDiscovered
(Optional) Select if you want to ignores segment ports with no discovered IP address bindings. This often indicates that the VM is simply powered off. (Default = False)

.EXAMPLE
./Compare-NsxRealizedToDiscoveredBindings.ps1 -SegmentId 3647b8cb-3136-4d84-bd8d-56813a9c760d -NsxFqdn nsx.sddc.lab | Out-GridView
#>

param (
    [Parameter(Mandatory = $true)]
    [string] $SegmentId,
    [Parameter(Mandatory = $true)]
    [string] $NsxFqdn,
    [System.Management.Automation.PSCredential] $AdminCreds = (Get-Credential -Message "Enter your NSX admin credentials"),
    [Switch] $ShowAll,
    [Switch] $OnlyIpv4,
    [Switch] $IgnoreEmptyDiscovered
)
# Login to NSX Manager. Quit if authentication fails.
$connectionResult = Connect-NsxServer -Server $nsxFqdn -Credential $adminCreds
if (-Not $connectionResult.IsConnected) {
    return
}

# Retrieve all segments if no specific segment provided
if ($null -eq $SegmentId -or '' -eq $SegmentId) {
    $segments = (Invoke-ListAllInfraSegments).Results
}
# Retrieve the specific segment if one was provided
else {
    $segments = Invoke-ReadInfraSegment -SegmentId $SegmentId
}

foreach ($segment in $segments) {
    $segmentPorts = Invoke-ListInfraSegmentPorts -SegmentId $segment.Id
    foreach ($port in $segmentPorts.Results) {
        $portState = Invoke-GetInfraSegmentPortState -SegmentId $segment.Id -PortId $port.Id

        # Retrieve the discovered and realized bindings for this segment port
        $discovered = $portState.DiscoveredBindings.Binding.IpAddress | Select-Object -Unique
        if ($OnlyIpv4) {
            $discovered = $discovered | Where-Object  { ([IpAddress]$_).AddressFamily -eq "InterNetwork" }
        }
        $realized = $portState.RealizedBindings.Binding.IpAddress | Select-Object -Unique
        if ($OnlyIpv4) {
            $realized = $realized | Where-Object  { ([IpAddress]$_).AddressFamily -eq "InterNetwork" }
        }

        # Replace null values of discovered or realized with an empty array so they can still work with Compare-Object
        if ($null -eq $discovered) { $discovered = @() }
        if ($null -eq $realized) { $realized = @() }

        # Skip if there are no discovered bindings and we're ignoring those
        if ($IgnoreEmptyDiscovered -and $discovered.Count -eq 0) {
            continue
        }
        
        # Compare the values of discovered and realized IP bindings to determine if there is a difference
        $comparison = Compare-Object -ReferenceObject $discovered -DifferenceObject $realized
        if ($ShowAll) {
            [pscustomobject]@{
                Segment = $segment.Id
                DisplayName = $port.DisplayName
                Mismatch = ($null -ne $comparison)
                DiscoveredBindings = (Sort-Object -InputObject $discovered) -join ", "
                RealizedBindings = (Sort-Object -InputObject $realized) -join ", "
            }
        }
        else {
            if ($null -ne $comparison) {
                [pscustomobject]@{
                    Segment = $segment.Id
                    DisplayName = $port.DisplayName
                    DiscoveredBindings = (Sort-Object -InputObject $discovered) -join ", "
                    RealizedBindings = (Sort-Object -InputObject $realized) -join ", "
                }
            }
        }
    }
}

Disconnect-NsxServer -Server $nsxFqdn