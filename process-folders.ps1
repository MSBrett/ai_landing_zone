param (
        [switch]$apply,
        [switch]$init,
        [switch]$plan,
        [switch]$refresh,
        [switch]$destroy
    )

clear-host
import-module -force ./module.psm1

try {
    push-location
    if ($init)
    {
        tf -init ./00-Subnets
        tf -init ./01-AAD
        tf -init ./02-Network
        tf -init ./03-Support
        tf -init ./04-AI
        tf -init ./05-AKS
    }

    if ($plan)
    {
        tf -plan ./00-Subnets
        tf -plan ./01-AAD
        tf -plan ./02-Network
        tf -plan ./03-Support
        tf -plan ./04-AI
        tf -plan ./05-AKS
    }

    if ($apply)
    {
        tf -apply ./00-Subnets
        tf -apply ./01-AAD
        tf -apply ./02-Network
        tf -apply ./03-Support
        tf -apply ./04-AI
        tf -apply ./05-AKS
    }

    if ($refresh)
    {
        tf -refresh ./00-Subnets
        tf -refresh ./01-AAD
        tf -refresh ./02-Network
        tf -refresh ./03-Support
        tf -refresh ./04-AI
        tf -refresh ./05-AKS
    }

    if ($destroy)
    {
        tf -destroy ./05-AKS
        tf -destroy ./04-AI
        tf -destroy ./03-Support
        tf -destroy ./02-Network
        #tf -destroy ./01-AAD
        #tf -destroy ./00-Subnets
    }
}
catch {
    Write-Output $_.Exception.Message
}
finally {
    Pop-Location
}
