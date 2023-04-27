
 
 #Providers

 terraform {
       backend "remote" {
         #The name of your Terraform Cloud organization.
         organization = "EV"

         # The name of the Terraform Cloud workspace to store Terraform state files in.
         workspaces {
           name = "Serverless_Website_Terraform"
         }
       }
     }


provider "azurerm" {
  features {}

  subscription_id   = ""
  tenant_id         = ""
  client_id         = ""
  client_secret     = ""
}



#variable "domain_name" {
#  default = "edwin-vasquez.com"
#}



#Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = "$resourceGroupName"
  location = "$region"




}
#Create and configure storage account
resource "azurerm_storage_account" "main" {
  name                      =  "$storageAccountName"
  location                  = "$region"
  resource_group_name       = "$resourceGroupName"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  access_tier               = "Hot"
  account_tier              = "Standard"
  allow_nested_items_to_be_public = "true"
  shared_access_key_enabled = true
  min_tls_version           = "TLS1_2"
  static_website {
    index_document = "index.html"
  }

}


#Create and configure container

resource "azurerm_storage_container" "name" {
  name                  = "website"
  storage_account_name  = "$storageAccountName"
  container_access_type = "private"

}

#Upload web files

/* 
resource "azurerm_storage_blob" "source_files" {
for_each = fileset("${path.module}/evweb/","*.*")
   name                   = each.value
  storage_account_name   = "$storageAccountName"
  storage_container_name = azurerm_storage_container.name.name
  type                   = "Block"
  source                 = "website/${each.value}"
  content_md5            = filemd5("evweb/${each.value}")
  } */

#Create CDN profile

resource "azurerm_cdn_profile" "evweb" {
  name                = "WebsiteApp-CDN"
  location            = "global"
  resource_group_name = "$resourceGroupName"
  sku                 = "Standard_Microsoft"
}
#Create CDN endpoint
resource "azurerm_cdn_endpoint" "evweb" {
  name                = "WebsiteApp-CDN-Endpoint"
  profile_name        = azurerm_cdn_profile.evweb.name
  location            = azurerm_cdn_profile.evweb.location
  resource_group_name = azurerm_resource_group.main.name

  origin {
    name = "website"
    /*  origin = "Storage static website" */
    host_name = trimsuffix(trimprefix(trimprefix(azurerm_storage_account.main.primary_blob_host, "https://"), "http://"), "/")
  }
}
/* data "azurerm_dns_zone" "example" {
  name                = "$domainName"
  resource_group_name = azurerm_resource_group.main.name
} */

/* resource "azurerm_dns_cname_record" "example" {
  name                = "cdn-WebApp"
  zone_name           = "$domainName"
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 3600
  target_resource_id  = azurerm_cdn_endpoint.evweb.id 
}*/

resource "azurerm_cdn_endpoint_custom_domain" "example" {
  name            = "WebApp-customdomain"
  cdn_endpoint_id = azurerm_cdn_endpoint.evweb.id
  host_name       = "$domainName"





}
