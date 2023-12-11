Function tf {
    param (
        [String]$folderName,
        [switch]$apply,
        [switch]$init,
        [switch]$plan,
        [switch]$destroy,
        [switch]$refresh,
        [string]$backend=".\backend.json"
    )

    Push-Location
    $config = Get-Content $backend | ConvertFrom-Json
    $STORAGEACCOUNTNAME=$config.STORAGEACCOUNTNAME
    $CONTAINERNAME=$config.CONTAINERNAME
    $TFSTATE_RG=$config.TFSTATE_RG
    $ACCESS_KEY=$config.ACCESS_KEY

    Write-Output "Setting the location to $folderName"
    Set-Location $folderName
    
    try {
        if ($init)
        {
            Write-Output "Init"
            terraform init -backend-config="resource_group_name=$TFSTATE_RG" -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME" -reconfigure -upgrade
        }

        if ($refresh)
        {
            Write-Output "Refresh"
            terraform refresh -var-file="..\terraform.tfvars" -var "access_key=$ACCESS_KEY" -compact-warnings
        }

        if ($plan)
        {
            Write-Output "Plan"
            terraform plan -var-file="..\terraform.tfvars" -var "access_key=$ACCESS_KEY" -compact-warnings
        }

        if ($apply)
        {
            Write-Output "Apply"
            terraform apply -var-file="..\terraform.tfvars" -var "access_key=$ACCESS_KEY" -auto-approve -compact-warnings
        }

        if ($destroy)
        {
            Write-Output "Destroy"
            terraform destroy -var-file="..\terraform.tfvars" -var "access_key=$ACCESS_KEY"
        }
    }
    catch {
        Write-Output $_.Exception.Message
    }
    finally {
        Pop-Location
    }
}

Export-ModuleMember -Function tf
