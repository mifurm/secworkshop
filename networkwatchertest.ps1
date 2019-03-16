Select-AzureRmContext 'Visual Studio Enterprise – MPN (9d4350c8-e11c-4007-a923-c1df11a52bab) - MSI@50342'
$networkWatcher = Get-AzureRmNetworkWatcher -Name 'NetworkWatcher_westeurope' -ResourceGroupName 'NetworkWatcherRG'
$vm=Get-AzurermVM -ResourceGroupName 'SecWorkshop' -Name vm02vnet02
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
