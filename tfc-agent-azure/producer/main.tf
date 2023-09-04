provider "azurerm" {
  subscription_id = "3ef4ffeb-d18c-41c3-b7d8-e4ce77dc05f2"
  skip_provider_registration = true
  use_msi = true
  use_cli = false
  features {}
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_container_group" "tfc-agent" {
  name                = "tfc-agent"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  os_type             = "Linux"
  restart_policy      = "Always"

  container {
    name   = "tfc-agent"
    image  = "smartramana/tfc-agent:latest"
    cpu    = "1.0"
    memory = "2.0"

    # this field seems to be mandatory (error happens if not there). See https://github.com/terraform-providers/terraform-provider-azurerm/issues/1697#issuecomment-608669422
    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      TFC_AGENT_SINGLE = "True"
      TFC_AGENT_NAME="az_agent-aci"
    }

    secure_environment_variables = {
      TFC_AGENT_TOKEN = var.tfc_agent_token
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

data "azurerm_subscription" "primary" {}

# you'll need to customize IAM policies to access resources as desired
resource "azurerm_role_assignment" "tfc-agent-role" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_container_group.tfc-agent.identity[0].principal_id
}
