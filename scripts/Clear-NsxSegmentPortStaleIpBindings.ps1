<#
.SYNOPSIS
Clears stale realized IP address bindings in an NSX segment port.

.DESCRIPTION
Clears stale realized IP address bindings in an NSX segment port.
A stale realized IP address could cause VMs to be matched to security groups incorrectly. This could then result in firewall rules not being properly applied to a VM.

.LINK
https://knowledge.broadcom.com/external/article/329047/stale-ips-in-lsp-realized-bindings-with.html

.PARAMETER SegmentId
Specifies the ID of the NSX segment to clear ports in.

.PARAMETER AdminCreds
Specifies the admin credentials used to log into NSX. By default, it prompts the user for credentials upon execution.

.PARAMETER NsxFqdn
Specifies the FQDN of the NSX server. Should be the NSX cluster's VIP.

.PARAMETER OnlyIpv4
(Optional) Select if you only want to check for IPv4 address bindings. All IPv6 addresses will be ignored. (Default = False)

.PARAMETER IgnoreEmptyDiscovered
(Optional) Select if you want to ignores segment ports with no discovered IP address bindings. This often indicates that the VM is simply powered off. (Default = False)

.PARAMETER NoConfirm
(Optional) Select if you do not want the script to ask for confirmation before clearing stale IP address bindings. (Default = False)

.EXAMPLE
./Clear-NsxSegmentPortStaleIpBindings.ps1 -SegmentId 3647b8cb-3136-4d84-bd8d-56813a9c760d -NsxFqdn nsx.sddc.lab
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $SegmentId,
    [Parameter(Mandatory = $true)]
    [string] $NsxFqdn,
    [System.Management.Automation.PSCredential] $AdminCreds = (Get-Credential -Message "Enter your NSX admin credentials"),
    [Switch] $OnlyIpv4,
    [Switch] $IgnoreEmptyDiscovered,
    [Switch] $NoConfirm
)

# Helper function that gets a list of stale realized IP addresses
function Get-BindingDifferences {
    param (
        $DiscoveredBindings,
        $RealizedBindings
    )
    # Collect all realized bindings that aren't in the discovered bindings list
    $differences = foreach ($realizedBinding in $realizedBindings) {
        if ($discoveredBindings -notcontains $realizedBinding) {
            Initialize-PortAddressBindingEntry -IpAddress $realizedBinding.IpAddress -MacAddress $realizedBinding.MacAddress -VlanId $realizedBinding.Vlan
        }
    }

    return $differences
}

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
        # Get the differences between the discovered and realized bindings for this port
        $portState = Invoke-GetInfraSegmentPortState -SegmentId $segment.Id -PortId $port.Id
        $discoveredBindings = $portState.DiscoveredBindings | Select-Object -ExpandProperty Binding
        $realizedBindings = $portState.RealizedBindings | Select-Object -ExpandProperty Binding
        if ($OnlyIpv4) {
            $discoveredBindings = $discoveredBindings | Where-Object  { ([IpAddress]$_.IpAddress).AddressFamily -eq "InterNetwork" }
            $realizedBindings = $realizedBindings | Where-Object  { ([IpAddress]$_.IpAddress).AddressFamily -eq "InterNetwork" }
        } 
        $differences = Get-BindingDifferences -DiscoveredBindings $discoveredBindings -RealizedBindings $realizedBindings

        # If there are no differences, continue to the next port
        if ($null -eq $differences){
            continue
        }
        if ($IgnoreEmptyDiscovered -and $null -eq $discoveredBindings) {
            continue
        }

        # Prompt the user with the differences and whether to sync the bindings
        Write-Host "*** $($port.DisplayName) ***"
        Write-Host "Discovered Bindings:"
        Format-Table -InputObject $discoveredBindings

        Write-Host "Realized Bindings:"
        Format-Table -InputObject $realizedBindings

        Write-Host "Non-matching Realized Bindings:"
        Format-Table -InputObject $differences

        if (-not $NoConfirm) {
            $decision = Read-Host -Prompt "Do you wish to remove the non-matching realized bindings for this segment port? [Y/N]"
        }
        if ($NoConfirm -or $decision -eq "Y") {
            # Add the stale IP address bindings to the ignored list
            $port.IgnoredAddressBindings = $differences
            Invoke-PatchInfraSegmentPort -SegmentId $segment.Id -PortId $port.Id -SegmentPort $port

            # Wait until there are no more differences between the discovered and realized bindings
            do {
                Start-Sleep -Seconds 1
                $currentPortState = Invoke-GetInfraSegmentPortState -SegmentId $segment.Id -PortId $port.Id
                $discoveredBindings = $currentPortState.DiscoveredBindings | Select-Object -ExpandProperty Binding
                $realizedBindings = $currentPortState.RealizedBindings | Select-Object -ExpandProperty Binding
                if ($OnlyIpv4) {
                    $discoveredBindings = $discoveredBindings | Where-Object  { ([IpAddress]$_.IpAddress).AddressFamily -eq "InterNetwork" }
                    $realizedBindings = $realizedBindings | Where-Object  { ([IpAddress]$_.IpAddress).AddressFamily -eq "InterNetwork" }
                } 
                $differences = Get-BindingDifferences -DiscoveredBindings $discoveredBindings -RealizedBindings $realizedBindings
            } while ( $null -ne $differences -and $differences.Count -gt 0)

            # Clean up the ignored address bindings list
            $port.IgnoredAddressBindings = @()
            Invoke-PatchInfraSegmentPort -SegmentId $segment.Id -PortId $port.Id -SegmentPort $port
        }
    }
}

Disconnect-NsxServer -Server $nsxFqdn