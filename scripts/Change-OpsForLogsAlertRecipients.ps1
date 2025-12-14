<#
.SYNOPSIS
Updates the email recipients for a list of alerts.

.PARAMETER AlertIds
Specifies a list of alert IDs to change recipients for.

.PARAMETER EmailRecipients
Specifies the new list of email addresses to set as the alerts' recipients.

.PARAMETER OpsForLogsFqdn
Specifies the FQDN of the VCF Operations for Logs server. Should be the Ops for Logs cluster's VIP.

.PARAMETER AdminCreds
Specifies the admin credentials used to log into VCF Operations for Logs. By default, it prompts the user for credentials upon execution.

.PARAMETER AuthenticationProvider
Specifies the authentication provider to use for logging in. Allowed values are likely Local, ActiveDirectory, or vIDM. (Default = "vIDM")

.EXAMPLE
./Change-OpsForLogsAlertRecipients.ps1 -AlertIds 3647b8cb-3136-4d84-bd8d-56813a9c760d,e8338b64-4a77-4379-b1a8-1cdf10074e19 -EmailRecipients admin@sddc.lab,admin-2@sddc.lab -OpsForLogsFqdn ops-logs.sddc.lab

#>
param (
    [Parameter(Mandatory = $true)]
    [string[]] $AlertIds,
    [Parameter(Mandatory = $true)]
    [string[]] $EmailRecipients,
    [Parameter(Mandatory = $true)]
    [string] $OpsForLogsFqdn,
    [System.Management.Automation.PSCredential] $AdminCreds = (Get-Credential -Message "Enter your Ops for Logs admin credentials"),
    [string] $AuthenticationProvider = "vIDM"
)

$body = @{
    recipients=@{
        emails=$EmailRecipients
    }
} | ConvertTo-Json

# Ops for Logs Authentication
$tokenResponse = Invoke-RestMethod -Authentication Bearer -Token $token -Method Patch -Uri "https://$($OpsForLogsFqdn):9543/api/v2/sessions" -ContentType "application/json" -Body (@{username=$AdminCreds.UserName;password=$AdminCreds.GetNetworkCredential().Password;provider=$AuthenticationProvider} | ConvertTo-Json)
$token = $tokenResponse.sessionId | ConvertTo-SecureString

foreach ($alertId in $alertIds) {
    Invoke-RestMethod -Authentication Bearer -Token $token -Method Patch -Uri "https://$($OpsForLogsFqdn):9543/api/v2/alerts/$alertId" -Body $body -ContentType "application/json"
}