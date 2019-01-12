az account set --subscription "MichalFurmankiewicz"

cd /Documents/Projekty/0.Community/Poznan-Cloud\&DataCenterDay#3/ENV
rgName=sec01rg
az group deployment create --name lab01 --resource-group $rgName --template-file deploy-env-v.1.1.json
