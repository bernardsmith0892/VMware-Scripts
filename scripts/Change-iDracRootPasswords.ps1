# Logs into iDRAC for all hosts and changes the root user's password
$iDracCreds = Get-Credential -UserName "root" -Title "Provide the current 'root' password for iDRAC"
$newPassword = Read-Host -AsSecureString -Prompt "Provide the NEW 'root' password for iDRAC"
Write-Host "Changing all 'root' passwords using this payload: '{`"Password`": `"$($newPassword | ConvertFrom-SecureString -AsPlainText)`"}'"
$confirm = Read-Host -Prompt "Confirm? [y/n]"

$iDracIpAddresses = 1..30 | ForEach-Object { "192.168.1.$_" }
if ($confirm -eq "y") {
    # User ID 2 is the 'root' account for all iDRACs
    $uri = "/redfish/v1/AccountService/Accounts/2"
    $urls = $iDracIpAddresses | ForEach-Object { "https://$_$uri"}
    $passwordChanges = foreach ($url in $urls) { Invoke-RestMethod -Uri $url -Credential $iDracCreds -SkipCertificateCheck -Method Patch -ContentType 'application/json' -Body "{`"Password`": `"$($newPassword | ConvertFrom-SecureString -AsPlainText)`"}"}
    $passwordChanges | Out-GridView
}
