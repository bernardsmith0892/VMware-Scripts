<#
.SYNOPSIS
Retrieves DFW rules and security groups for a domain in NSX and outputs them as Terraform import blocks.

.DESCRIPTION
Retrieves DFW rules and security groups for a domain in NSX and outputs them as Terraform import blocks.

.PARAMETER NsxFqdn
Specifies the FQDN of the NSX server. Should be the NSX cluster's VIP.

.PARAMETER AdminCreds
Specifies the admin credentials used to log into NSX. By default, it prompts the user for credentials upon execution.

.PARAMETER DomainId
(Optional) The ID of the NSX domain to retrieve values for. (Default = 'default')

.PARAMETER OutFile
(Optional) Writes the output to a given filepath. OVERWRITES THE FILE, IF IT EXISTS. By default, write to standard output.

.PARAMETER ShowSystemPolicies
(Optional) Select if you also want to include system/pre-generated DFW policies. (Default = False)

.PARAMETER ShowSystemPolicies
(Optional) Select if you also want to include system/pre-generated security groups. (Default = False)

.PARAMETER SkipCertificateCheck
(Optional) Select if you want to skip the certificate check for the NSX REST API calls (Default = False)

.EXAMPLE
./Export-NsxDfwAndGroupsToTerraform.psq -NsxFqdn nsx.sddc.lab -OutFile import.tf
#>

param (
    [Parameter(Mandatory=$true)]
    [string] $NsxFqdn,
    [System.Management.Automation.PSCredential] $AdminCreds = (Get-Credential -Message "Enter your NSX admin credentials"),
    [string] $DomainId = "default",
    [string] $OutFile,
    [switch] $ShowSystemPolicies,
    [switch] $ShowSystemGroups,
    [switch] $SkipCertificateCheck
)

if ([string]::IsNullOrEmpty($OutFile)) {
    Write-Output "# *** DFW Policies ***"   
}
else {
    Out-File -FilePath $OutFile -InputObject "# *** DFW Policies ***"   
}

$policiesRequest = Invoke-RestMethod -ErrorAction Stop -Credential $AdminCreds -Authentication Basic -Method Get -Uri "https://$NsxFqdn/policy/api/v1/infra/domains/$DomainId/security-policies" -SkipCertificateCheck:$SkipCertificateCheck
foreach ($policy in $policiesRequest.results) {
    if (-not $ShowSystemPolicies -and $policy._create_user -eq "system"){
        continue
    }

    $policyCleanName = $policy.display_name -replace '[^a-zA-Z0-9-_]','-'
    $import_block = @"
import {
    to = nsxt_policy_security_policy.$policyCleanName
    id = "$DomainId/$($policy.id)"
}
"@

    if ([string]::IsNullOrEmpty($OutFile)) {
        Write-Output $import_block
    }
    else {
        Out-File -FilePath $OutFile -Append -InputObject $import_block
    }
}

if ([string]::IsNullOrEmpty($OutFile)) {
    Write-Output "# *** Group Policies ***"   
}
else {
    Out-File -FilePath $OutFile -Append -InputObject "# *** Group Policies ***"   
}
$groupsRequest = Invoke-RestMethod -ErrorAction Stop -Credential $AdminCreds -Authentication Basic -Method Get -Uri "https://$NsxFqdn/policy/api/v1/infra/domains/$DomainId/groups" -SkipCertificateCheck:$SkipCertificateCheck
foreach ($group in $groupsRequest.results) {
    if (-not $ShowSystemGroups -and $group._create_user -eq "system"){
        continue
    }
    
    $groupCleanName = $group.display_name -replace '[^a-zA-Z0-9-_]','-'

    $import_block = @"
import {
    to = nsxt_policy_group.$groupCleanName
    id = "$DomainId/$($group.id)"
}
"@
    if ([string]::IsNullOrEmpty($OutFile)) {
        Write-Output $import_block
    }
    else {
        Out-File -FilePath $OutFile -Append -InputObject $import_block
    }
}