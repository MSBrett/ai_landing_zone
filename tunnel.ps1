$bastion_name='workload-vnet-bastion'
$rg='AI-SANDBOX'
$vm_id='/subscriptions/cab7feeb-759d-478c-ade6-9326de0651ff/resourceGroups/AI-SANDBOX/providers/Microsoft.Compute/virtualMachines/linuxvm'
az network bastion tunnel -n $bastion_name -g $rg --target-resource-id $vm_id --resource-port 22 --port 2022 --timeout 60 --auth-type "AAD"

git config --global user.email "msbrett@users.no-reply.github.com"
git config --global user.name "MSBrett"