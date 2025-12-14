# Lists physical NIC CDP information for all hosts
# Requires you to already be connected to one or more vCenter servers
$hosts = Get-VMHost
$views = Get-View $hosts.ExtensionData.ConfigManager.NetworkSystem
$views | Select-Object @{"Name"="Hostname";"Expr"={$_.DnsConfig.HostName}}, `
    @{"Name"="Switch-vmnic0";"Expr"={$_.QueryNetworkHint("vmnic0").ConnectedSwitchPort.DevId}},@{"Name"="Switchport-vmnic0";"Expr"={$_.QueryNetworkHint("vmnic0").ConnectedSwitchPort.PortId}}, `
    @{"Name"="Switch-vmnic1";"Expr"={$_.QueryNetworkHint("vmnic1").ConnectedSwitchPort.DevId}},@{"Name"="Switchport-vmnic1";"Expr"={$_.QueryNetworkHint("vmnic1").ConnectedSwitchPort.PortId}}, `
    @{"Name"="Switch-vmnic2";"Expr"={$_.QueryNetworkHint("vmnic2").ConnectedSwitchPort.DevId}},@{"Name"="Switchport-vmnic2";"Expr"={$_.QueryNetworkHint("vmnic2").ConnectedSwitchPort.PortId}}, `
    @{"Name"="Switch-vmnic3";"Expr"={$_.QueryNetworkHint("vmnic3").ConnectedSwitchPort.DevId}},@{"Name"="Switchport-vmnic3";"Expr"={$_.QueryNetworkHint("vmnic3").ConnectedSwitchPort.PortId}} `
    | Out-GridView -Title "ESXi Host Physical NIC CDP Information"