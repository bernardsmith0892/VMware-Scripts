<#
.SYNOPSIS
Logs into Aria Automation and returns the authentication token.

.PARAMETER AutoFqdn
Specifies the FQDN of Aria Automation.

.PARAMETER AdminCreds
Specifies the admin credentials used to log into Aria Automation. By default, it prompts the user for credentials upon execution.

.EXAMPLE
# All Systems
$token = ./Get-VcfAutoApiToken.ps1 -AutoFqdn auto.sddc.lab
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $AutoFqdn,
    [System.Management.Automation.PSCredential] $AdminCreds = (Get-Credential -Message "Enter your NSX admin credentials")
)

$apiToken = Invoke-RestMethod -Method Post -Uri "$autoFqdn/csp/gateway/am/api/login?access_token" -Body "{`"username`": `"$($adminCreds.UserName)`", `"password`": `"$($adminCreds.GetNetworkCredential().Password)`"}" -ContentType 'application/json'
$bearerToken = Invoke-RestMethod -Method Post -Uri "$autoFqdn/iaas/api/login" -Body "{`"refreshToken`": `"$($apiToken.refresh_token)`"}" -ContentType 'application/json'
$tokenSecure = ConvertTo-SecureString -String $bearerToken.token -AsPlainText -Force
return $tokenSecure