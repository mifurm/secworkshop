az account list --query [].id > subs.list
for n in $(cat subs.list) 
do 
        temp=$(eval echo $n)
        temp=${temp:0:36}
        az resource list --subscription $temp --query [].type;
done
