#diskEncryption

#encrypt the disk
$rgName = 'securityWorkshopRG';
$vmName = 'vm01diskenc';
$KeyVaultName = 'keyva01';
$KeyVault = Get-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName $rgname;
$diskEncryptionKeyVaultUrl = $KeyVault.VaultUri;
$KeyVaultResourceId = $KeyVault.ResourceId;

Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $rgName -VMName $vmName -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId -Force;

#validate disk encryption
$rgName = 'securityWorkshopRG';
$vmName = 'vm01diskenc';
Get-AzureRmVmDiskEncryptionStatus -ResourceGroupName $rgName -VMName $vmName
