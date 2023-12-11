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
        tf -init .\03-AAD-import
        tf -init .\04-Network-Hub
        tf -init .\05-Network-LZ
        tf -init .\06-AKS-supporting
        tf -init .\07-AKS-cluster
        tf -init .\08-AI
    }

    if ($plan)
    {
        tf -plan .\03-AAD-import
        tf -plan .\04-Network-Hub
        tf -plan .\05-Network-LZ
        tf -plan .\06-AKS-supporting
        tf -plan .\07-AKS-cluster
        tf -plan .\08-AI
    }

    if ($apply)
    {
        tf -apply .\03-AAD-import
        tf -apply .\04-Network-Hub
        tf -apply .\05-Network-LZ
        tf -apply .\06-AKS-supporting
        tf -apply .\07-AKS-cluster
        tf -apply .\08-AI
    }

    if ($refresh)
    {
        tf -refresh .\03-AAD-import
        tf -refresh .\04-Network-Hub
        tf -refresh .\05-Network-LZ
        tf -refresh .\06-AKS-supporting
        tf -refresh .\07-AKS-cluster
        tf -refresh .\08-AI
    }

    if ($destroy)
    {
        tf -destroy .\08-AI
        tf -destroy .\07-AKS-cluster
        tf -destroy .\06-AKS-supporting
        tf -destroy .\05-Network-LZ
        tf -destroy .\04-Network-Hub
        tf -destroy .\03-AAD-import
    }
}
catch {
    Write-Output $_.Exception.Message
}
finally {
    Pop-Location
}
