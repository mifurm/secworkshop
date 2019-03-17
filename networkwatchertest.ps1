
Select-AzureRmContext <SUBSCRIPTION CONTEXT>

$rg='SecWorkshop' 
$vmName = 'vm02vnet02'
$netW=Get-AzureRmNetworkWatcher -ResourceGroupName 'NetworkWatcherRG'
$networkWatcher = $netW[0]

$vm=Get-AzurermVM -ResourceGroupName $rg -Name $vmName
$nics = Get-AzureRmNetworkInterface | Where {$_.Id -eq $vm.NetworkProfile.NetworkInterfaces[0].Id}
Test-AzureRmNetworkWatcherIPFlow `
  -NetworkWatcher $networkWatcher `
  -TargetVirtualMachineId $vm.Id `
  -Direction Outbound `
  -LocalIPAddress $nics[0].IpConfigurations[0].PrivateIpAddress `
  -Protocol TCP `
  -LocalPort 60000 `
  -RemoteIPAddress 212.77.98.9 `
  -RemotePort 80 -Debug
