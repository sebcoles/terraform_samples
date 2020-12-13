locals {
  api_name            = var.api_name
  resource_group_name = var.resource_group_name
  location            = var.location
  api_management_name = var.api_management_name
  default_hostname    = var.default_hostname
  host_key            = var.host_key
  key_vault_id        = var.key_vault_id
}

resource "azurerm_api_management_backend" "fa_api" {
  name                = local.api_name
  resource_group_name = local.resource_group_name
  api_management_name = local.api_management_name
  protocol            = "http"
  url                 = "https://${local.default_hostname}"
}

resource "azurerm_api_management_api" "index" {
  name                = local.api_name
  resource_group_name = local.resource_group_name
  api_management_name = local.api_management_name
  revision            = "1"
  display_name        = local.api_name
  path                = ""
  protocols           = ["https"]
  service_url         = "https://${local.default_hostname}/api/"
}

resource "azurerm_api_management_api_policy" "policy" {
  api_name            = azurerm_api_management_api.index.name
  api_management_name = azurerm_api_management_api.index.api_management_name
  resource_group_name = azurerm_api_management_api.index.resource_group_name

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <!-- Look for func-host-key in the cache -->
    <cache-lookup-value key="func-host-key-${local.host_key.version}" variable-name="funchostkey" />
    <!-- If API Management doesn’t find it in the cache, make a request for it and store it -->
    <choose>
      <when condition="@(!context.Variables.ContainsKey("funchostkey"))">
        <!-- Make HTTP request to get function host key -->
        <send-request ignore-error="false" timeout="20" response-variable-name="coderesponse" mode="new">
          <set-url>${local.host_key.id}?api-version=7.0</set-url>
          <set-method>GET</set-method>
          <authentication-managed-identity resource="https://vault.azure.net" />
        </send-request>
        <!-- Store response body in context variable -->
        <set-variable name="funchostkey" value="@((string)((IResponse)context.Variables["coderesponse"]).Body.As<JObject>()["value"])" />
        <!-- Store result in cache -->
        <cache-store-value key="func-host-key-${local.host_key.version}" value="@((string)context.Variables["funchostkey"])" duration="100000" />
      </when>
    </choose>
    <set-header name="x-functions-key" exists-action="override">
      <value>@((string)context.Variables["funchostkey"])</value>
    </set-header>
  </inbound>
</policies>
XML
}

resource "azurerm_api_management_api_operation" "get" {
  operation_id        = "get"
  api_name            = azurerm_api_management_api.index.name
  api_management_name = azurerm_api_management_api.index.api_management_name
  resource_group_name = azurerm_api_management_api.index.resource_group_name
  display_name        = "Get"
  method              = "GET"
  url_template        = "/"
}