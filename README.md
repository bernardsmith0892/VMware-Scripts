# VMware Scripts

A miscellaneous list of useful scripts I've developed for tasks in VMware Cloud Foundation.

## vSphere

### [Apply-SettingToESXiHosts_Template.ps1](scripts/Apply-SettingToESXiHosts_Template.ps1)

A template script -- useful if you need to run a set of commands on multiple ESXi hosts which requires a reboot after execution. Places a host into maintenance mode, runs the command, reboots the host, takes the host out of maintenance mode, and then moves on to the next host. Insert your code into the commented area, add a reason in the host shutdown command, and execute the cmdlet.

### [Get-CDPInfo.ps1](scripts/Get-CDPInfo.ps1)

Used to list CDP information for the physical NICs of multiple ESXi hosts.

## NSX

### [Compare-NsxRealizedToDiscoveredBindings.ps1](scripts/Compare-NsxRealizedToDiscoveredBindings.ps1)

Compares the IP bindings for all segments ports in an NSX segment. Used to identify stale realized IP address bindings.

### [Clear-NsxSegmentPortStaleIpBindings.ps1](scripts/Clear-NsxSegmentPortStaleIpBindings.ps1)

Clears stale realized IP address bindings for all segment ports in an NSX segment.

### [Get-NsxFlowTableStatistics.ps1](scripts/Get-NsxFlowTableStatistics.ps1)

Retrieves the enhanced datapath flow table statistics for all ESXi hosts managed by NSX.

## Aria Suite

### [Change-OpsForLogsAlertRecipients.ps1](scripts/Change-OpsForLogsAlertRecipients.ps1)

Changes the email recipients for a list of VCF Operations for Logs alerts.

### [vIDM-Clear-SMTP.md](scripts/vIDM-Clear-SMTP.md)

Shows the two REST calls needed to clear an SMTP configuration in vIDM. You're normally unable to clear vIDM's SMTP settings through the GUI because it attempts to validate the SMTP settings before letting you save the configuration. Updating the SMTP configuration through the REST API bypasses this validation step, allowing you to set the SMTP host to a blank value.

### [Get-AriaAutoApiToken.ps1](scripts/Get-AriaAutoApiToken.ps1)

Logs into Aria Automation and returns the bearer token used for future REST API calls.
