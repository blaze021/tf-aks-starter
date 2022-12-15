variable "resource_group_name" {
  type    = string
  default = "dummy-aks-rg"
}

variable "resource_location" {
  type    = string
  default = "southcentralus"
}

variable "aks_resource_name" {
  type    = string
  default = "aks-dummy-instance"
}

variable "aks_agentpool_name" {
  type    = string
  default = "agentpool"
}