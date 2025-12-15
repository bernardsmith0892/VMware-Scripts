# Logs into iDRAC for all hosts and outputs the Service Tag and Secure Boot settings
$iDracCreds = Get-Credential -Title "Provide the 'root' password for iDRAC" -UserName "root"
$uri = "/redfish/v1/Systems/System.Embedded.1/Bios"
$iDracIpAddresses = 1..30 | ForEach-Object { "192.168.1.$_" }
$urls = $iDracIpAddresses | ForEach-Object { "https://$_$uri"}
$biosSettings = foreach ($url in $urls) { Invoke-RestMethod -Uri $url -Credential $iDracCreds -SkipCertificateCheck }
$biosSettings.Attributes | Select-Object SystemServiceTag,SecureBoot | Format-Table