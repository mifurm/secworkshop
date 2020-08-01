# Subscription ID to which the policy will be attached
$sub="xxx"
$tenantId="xxx"
 
Connect-AzAccount -Tenant $tenantId -SubscriptionId $sub
Set-AzContext -SubscriptionID $sub
 
#
 
$_scope="/subscriptions/$sub"
 
# Location Policy
$LocationPolicy = Get-AzPolicyDefinition -BuiltIn | Where-Object {$_.Properties.DisplayName -eq 'Allowed locations'}
$Locations = (Get-AzLocation | where DisplayName -like '*Europe')
 
# dodać inne regiony europejskiej poza UK
 
$AllowedLocations = @{'listOfAllowedLocations'=($Locations.location)}
New-AzPolicyAssignment -Name 'RestrictLocationPolicyAssignment' -PolicyDefinition $LocationPolicy -Scope $_scope -PolicyParameterObject $AllowedLocations
 
# VM Sizes Policy
$VMSizesPolicy = Get-AzPolicyDefinition -BuiltIn | Where-Object {$_.Properties.DisplayName -eq 'Allowed virtual machine SKUs'}
$sku=Get-AzVMSize -Location westeurope | where Name -like 'Standard_*' `
    | where Name -notlike 'Standard_N*' `
    | where Name -notlike 'Standard_H*' `
    | where Name -notlike 'Standard_G*' `
    | where Name -notlike 'Standard_L*' `
    | where Name -notlike 'Standard_M*' `
    | where Name -notlike 'Standard_E*' `
    | where NumberOfCores -ge 1 `
    | where NumberOfCores -le 16
 
$listOfAllowedSKUs = @{'listOfAllowedSKUs'=($sku.Name)}
New-AzPolicyAssignment -Name 'RestrictVMSKUsPolicyAssignment' -PolicyDefinition $VMSizesPolicy -Scope $_scope -PolicyParameterObject $listOfAllowedSKUs
 

$AllowedResourceTypesPolicy = Get-AzPolicyDefinition -BuiltIn | Where-Object {$_.Properties.DisplayName -eq 'Not allowed resource types'}
 
$resourcesProvidersList_NotMicrosoft=(Get-AzResourceProvider -ListAvailable | Select-Object ProviderNamespace, RegistrationState `
| where ProviderNamespace -notlike 'Microsoft.*')
 
$resourcesProvidersList_Classics=(Get-AzResourceProvider -ListAvailable | Select-Object ProviderNamespace, RegistrationState `
| where ProviderNamespace -like 'Microsoft.Classic*')
 
$CustomList=New-Object System.Collections.Generic.List[System.Object]
$CustomList.Add('Microsoft.WindowsIoT')
$CustomList.Add('Microsoft.SaaS')
$CustomList.Add('Microsoft.Experimentation')
$CustomList.Add('Microsoft.CustomProviders')
$CustomList.Add('Microsoft.ProjectBabylon')
$CustomList.Add('Microsoft.CognitiveServices')
$CustomList.Add('Microsoft.StorSimple')
$CustomList.Add('Microsoft.DocumentDB')
 
$resourcesProvidersList_Custom = New-Object System.Collections.Generic.List[System.Object]
 
foreach ($res in $CustomList)
{
    $o=Get-AzResourceProvider -ProviderNamespace $res | Select-Object ProviderNamespace, RegistrationState;
    $resourcesProvidersList_Custom.Add($o)
}
 
$resourcesProvidersList = New-Object System.Collections.Generic.List[System.Object]
 
$resourcesProvidersList=$resourcesProvidersList_NotMicrosoft+$resourcesProvidersList_Classics+$resourcesProvidersList_Custom;
#$resourcesProvidersList.Add($resourcesProvidersList_Custom);
 
$resourcesTypes = New-Object System.Collections.Generic.List[System.Object]
 
foreach ($resource in $resourcesProvidersList)
{
    #$resource.ProviderNamespace
    $listOfTypes=(Get-AzResourceProvider -ProviderNamespace $resource.ProviderNamespace).ResourceTypes.ResourceTypeName
    #$listOfTypes
    foreach($type in $listOfTypes)
    {
        $temp=$resource.ProviderNamespace
        $temp="$temp/$type"
        $resourcesTypes.Add($temp);
    }
}
 
$listOfResourceTypesNotAllowed = @{'listOfResourceTypesNotAllowed'=($resourcesTypes.ToArray())}
 
New-AzPolicyAssignment -Name 'RestrictResourcesTypesNotAllowed' -PolicyDefinition $AllowedResourceTypesPolicy -Scope $_scope -PolicyParameterObject $listOfResourceTypesNotAllowed
 
 
