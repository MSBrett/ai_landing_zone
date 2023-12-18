param (
        [switch]$apply,
        [switch]$init,
        [switch]$plan,
        [switch]$refresh,
        [switch]$destroy
    )

clear-host
import-module -force .\module.psm1

try {
    push-location
    if ($init)
    {
        tf -init .\01-AAD-Import
        tf -init .\02-Network-Hub
        tf -init .\03-Network-LZ
        tf -init .\04-Supporting-Services
        tf -init .\05-AKS-Cluster
        tf -init .\06-AI-Services
    }

    if ($plan)
    {
        tf -plan .\01-AAD-Import
        tf -plan .\02-Network-Hub
        tf -plan .\03-Network-LZ
        tf -plan .\04-Supporting-Services
        tf -plan .\05-AKS-Cluster
        tf -plan .\06-AI-Services
    }

    if ($apply)
    {
        tf -apply .\01-AAD-Import
        tf -apply .\02-Network-Hub
        tf -apply .\03-Network-LZ
        tf -apply .\04-Supporting-Services
        tf -apply .\05-AKS-Cluster
        tf -apply .\06-AI-Services
    }

    if ($refresh)
    {
        tf -refresh .\01-AAD-Import
        tf -refresh .\02-Network-Hub
        tf -refresh .\03-Network-LZ
        tf -refresh .\04-Supporting-Services
        tf -refresh .\05-AKS-Cluster
        tf -refresh .\06-AI-Services
    }

    if ($destroy)
    {
        tf -destroy .\06-AI-Services
        tf -destroy .\05-AKS-Cluster
        tf -destroy .\04-Supporting-Services
        tf -destroy .\03-Network-LZ
        tf -destroy .\02-Network-Hub
        #tf -destroy .\03-AAD-import
    }
}
catch {
    Write-Output $_.Exception.Message
}
finally {
    Pop-Location
}
