Set-AzContext -Subscription "mifurmlab"
$version = "9.4"
$ExtPublisher = "Microsoft.Azure.Monitoring.DependencyAgent"
$OsExtensionMap = @{ "Windows" = "DependencyAgentWindows"; "Linux" = "DependencyAgentLinux" }
#choose propoer sec group
#$rmgroup = "sec01rg"
$rgs=Get-AzureRmResourceGroup
ForEach ($rg in $rgs)
{
Get-AzureRmVM -ResourceGroupName $rg.ResourceGroupName |
ForEach-Object {
    ""
    $name = $_.Name
    $os = $_.StorageProfile.OsDisk.OsType
    $location = $_.Location
    $vmRmGroup = $_.ResourceGroupName
    If ($name -notlike 'kali*'){
    "${name}: ${os} (${location})"
    Date -Format o
    $ext = $OsExtensionMap.($os.ToString())
    $result = Set-AzureRmVMExtension -ResourceGroupName $vmRmGroup -VMName $name -Location $location `
    -Publisher $ExtPublisher -ExtensionType $ext -Name "DependencyAgent" -TypeHandlerVersion $version -NoWait
    $result.IsSuccessStatusCode
    }
}
}
