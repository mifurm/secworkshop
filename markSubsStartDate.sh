az tag create --resource-id "/subscriptions/ffca029c-a6e3-4630-9dfc-ff43256cd2f8" --tags StartDate=20.08.2021

az account list --query [].id > subs.list
for n in $(cat subs.list) 
do 
        temp=$(eval echo $n)
        temp=${temp:0:36}
        az tag list --resource-id "/subscriptions/$temp"
done
