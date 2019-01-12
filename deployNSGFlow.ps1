#set values
$rg="sec01rg"
$storage="sec01logs2"
$logAnalyticsWorkspace="sec01loganal"

#be sure to set them to proper locations

$NW = Get-AzurermNetworkWatcher -ResourceGroupName NetworkWatcherRG -Name NetworkWatcher_westeurope
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $rg -Name $storage
$workspace = Get-AzureRmOperationalInsightsWorkspace -Name $logAnalyticsWorkspace -ResourceGroupName $rg
$nsgs=Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rg
foreach ($nsg in $nsgs)
{
    Set-AzureRmNetworkWatcherConfigFlowLog -NetworkWatcher $NW -TargetResourceId $nsg.Id -EnableFlowLog $true -EnableTrafficAnalytics -Workspace $workspace -StorageAccountId $storageAccount.id -EnableRetention $true -RetentionInDays 1
}
