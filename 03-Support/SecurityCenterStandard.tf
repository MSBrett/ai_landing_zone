data "azurerm_subscription" "current" {}

# Assign the Microsoft Cloud Security Benchmark Policy initiative to the subscription (Foundational CSPM)
resource "azurerm_subscription_policy_assignment" "mcsb_assignment" {
  name                 = "mcsb"
  display_name         = "Microsoft Cloud Security Benchmark"
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
  subscription_id      = data.azurerm_subscription.current.id
}

# Enable Defender for Azure Resource Manager
resource "azurerm_security_center_subscription_pricing" "mdc_arm" {
  tier          = "Standard"
  resource_type = "Arm"
  subplan       = "PerApiCall"
}

# Enable Defender for Servers P2
resource "azurerm_security_center_subscription_pricing" "mdc_servers" {
  tier          = "Standard"
  resource_type = "VirtualMachines"
  subplan       = "P2"
}

# Enable Defender CSPM
resource "azurerm_security_center_subscription_pricing" "mdc_cspm" {
  tier          = "Standard"
  resource_type = "CloudPosture"
}

# Enable Defender for Storage (v2)
resource "azurerm_security_center_subscription_pricing" "mdc_storage" {
  tier          = "Standard"
  resource_type = "StorageAccounts"
  subplan       = "DefenderForStorageV2"

  extension {
    additional_extension_properties = {}
    name                            = "SensitiveDataDiscovery"
  }
}

# Enable integration with and auto-provisioning of Microsoft Defender for Endpoint (in the context of Defender for Servers)
resource "azurerm_security_center_setting" "setting_mde" {
  setting_name = "WDATP"
  enabled      = true
}

# Enabling Microsoft Defender Vulnerability Management as the Vulnerability Assessment provider for Defender for Servers
resource "azapi_resource" "DfSMDVMSettings" {
  type = "Microsoft.Security/serverVulnerabilityAssessmentsSettings@2022-01-01-preview"
  name = "AzureServersSetting"
  parent_id = data.azurerm_subscription.current.id
  body = jsonencode({
    properties = {
      selectedProvider = "MdeTvm"
    }
	kind = "AzureServersSetting"
  })
  schema_validation_enabled = false
}

# Enabling agentless Virtual Machine scanning
resource "azapi_resource" "setting_agentless_vm" {
  type = "Microsoft.Security/vmScanners@2022-03-01-preview"
  name = "default"
  parent_id = data.azurerm_subscription.current.id
  body = jsonencode({
    properties = {
      scanningMode = "Default"
    }
  })
  schema_validation_enabled = false
}

# Enabling sensitive data discovery and container registries vulnerability assessments while keeping agentless discovery for Kubernetes disabled
resource "azapi_update_resource" "setting_cspm" {
  type = "Microsoft.Security/pricings@2023-01-01"
  name = "CloudPosture"
  parent_id = data.azurerm_subscription.current.id
  body = jsonencode({
    properties = {
      pricingTier = "Standard"
      extensions = [
         {
             name = "SensitiveDataDiscovery"
             isEnabled = "True"
         },
         {
             name = "ContainerRegistriesVulnerabilityAssessments"
             isEnabled = "True"
         },
         {
             name = "AgentlessDiscoveryForKubernetes"
             isEnabled = "False"
         }
      ]
    }
  })
}

# Setting up the Security contacts
resource "azurerm_security_center_contact" "mdc_contact" {
  email = var.security_center_contact_email
  phone = var.security_center_contact_phone

  alert_notifications = true
  alerts_to_admins    = true
}

# Turning on Log Analytics agent auto-provisioning
resource "azurerm_security_center_auto_provisioning" "auto-provisioning" {
  auto_provision = "On"
}

# Associating the Log Analytics workspace with Microsoft Defender for Cloud
resource "azurerm_security_center_workspace" "la_workspace" {
  scope        = data.azurerm_subscription.current.id
  workspace_id = var.azurerm_log_analytics_workspace_id
}

# Enabling Defender for Servers P2 on the Log Analytics workspace (to benefit from 500 MB of free data ingestion per day)
resource "azurerm_log_analytics_solution" "la_workspace_security" {
  solution_name         = "Security"
  location              = var.azurerm_log_analytics_workspace_location
  resource_group_name   = var.azurerm_log_analytics_workspace_rg
  workspace_resource_id = var.azurerm_log_analytics_workspace_id
  workspace_name        = var.azurerm_log_analytics_workspace_name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Security"
  }
}

# Enabling Defender for Cloud Foundational CSPM on the Log Analytics workspace
resource "azurerm_log_analytics_solution" "la_workspace_securityfree" {
  solution_name         = "SecurityCenterFree"
  location              = var.azurerm_log_analytics_workspace_location
  resource_group_name   = var.azurerm_log_analytics_workspace_rg
  workspace_resource_id = var.azurerm_log_analytics_workspace_id
  workspace_name        = var.azurerm_log_analytics_workspace_name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityCenterFree"
  }
}

# Configuring continuous export to the Log Analytics workspace
resource "azurerm_security_center_automation" "la-exports" {
  name                = "ExportToWorkspace"
  location              = var.azurerm_log_analytics_workspace_location
  resource_group_name   = var.azurerm_log_analytics_workspace_rg

  action {
    type              = "loganalytics"
    resource_id       = var.azurerm_log_analytics_workspace_id
  }

  source {
    event_source = "Alerts"
    rule_set {
      rule {
        property_path  = "Severity"
        operator       = "Equals"
        expected_value = "High"
        property_type  = "String"
      }
      rule {
        property_path  = "Severity"
        operator       = "Equals"
        expected_value = "Medium"
        property_type  = "String"
      }
    }
  }

  source {
    event_source = "SecureScores"
  }

  source {
    event_source = "SecureScoreControls"
  }

  scopes = [ data.azurerm_subscription.current.id ]
}