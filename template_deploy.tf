resource "azurerm_resource_group" "aks_temp_rg" {
  name     = var.resource_group_name
  location = var.resource_location
}

resource "azurerm_template_deployment" "aks-template" {
  name = "aks-dummy-template"
  resource_group_name = azurerm_resource_group.aks_temp_rg.name

  template_body = <<DEPLOY
  {
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "resourceName": {
            "type": "string",
            "defaultValue": "${var.aks_resource_name}",
            "metadata": {
                "description": "The name of the Managed Cluster resource."
            }
        },
        "location": {
            "type": "string",
            "defaultValue": "${var.resource_location}",
            "metadata": {
                "description": "The location of AKS resource."
            }
        },
        "dnsPrefix": {
            "type": "string",
            "defaultValue": "${var.aks_resource_name}-${var.resource_location}-dns",
            "metadata": {
                "description": "Optional DNS prefix to use with hosted Kubernetes API server FQDN."
            }
        },
        "osDiskSizeGB": {
            "type": "int",
            "defaultValue": 0,
            "metadata": {
                "description": "Disk size (in GiB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize."
            },
            "minValue": 0,
            "maxValue": 1023
        },
        "kubernetesVersion": {
            "type": "string",
            "defaultValue": "1.23.8",
            "metadata": {
                "description": "The version of Kubernetes."
            }
        },
        "networkPlugin": {
            "type": "string",
            "defaultValue": "kubenet",
            "allowedValues": [
                "azure",
                "kubenet"
            ],
            "metadata": {
                "description": "Network plugin used for building Kubernetes network."
            }
        },
        "enableRBAC": {
            "type": "bool",
            "defaultValue": true,
            "metadata": {
                "description": "Boolean flag to turn on and off of RBAC."
            }
        },
        "vmssNodePool": {
            "type": "bool",
            "defaultValue": false,
            "metadata": {
                "description": "Boolean flag to turn on and off of virtual machine scale sets"
            }
        },
        "windowsProfile": {
            "type": "bool",
            "defaultValue": false,
            "metadata": {
                "description": "Boolean flag to turn on and off of virtual machine scale sets"
            }
        },
        "nodeResourceGroup": {
            "type": "string",
            "defaultValue": "MC_wmdemo-rg_${var.aks_resource_name}_${var.resource_location}",
            "metadata": {
                "description": "The name of the resource group containing agent pool nodes."
            }
        },
        "adminGroupObjectIDs": {
            "type": "array",
            "defaultValue": [],
            "metadata": {
                "description": "An array of AAD group object ids to give administrative access."
            }
        },
        "azureRbac": {
            "type": "bool",
            "defaultValue": false,
            "metadata": {
                "description": "Enable or disable Azure RBAC."
            }
        },
        "disableLocalAccounts": {
            "type": "bool",
            "defaultValue": false,
            "metadata": {
                "description": "Enable or disable local accounts."
            }
        },
        "enablePrivateCluster": {
            "type": "bool",
            "defaultValue": false,
            "metadata": {
                "description": "Enable private network access to the Kubernetes cluster."
            }
        },
        "enableHttpApplicationRouting": {
            "type": "bool",
            "defaultValue": true,
            "metadata": {
                "description": "Boolean flag to turn on and off http application routing."
            }
        },
        "enableAzurePolicy": {
            "type": "bool",
            "defaultValue": false,
            "metadata": {
                "description": "Boolean flag to turn on and off Azure Policy addon."
            }
        },
        "enableSecretStoreCSIDriver": {
            "type": "bool",
            "defaultValue": false,
            "metadata": {
                "description": "Boolean flag to turn on and off secret store CSI driver."
            }
        }
    },
    "resources": [
        {
            "apiVersion": "2022-06-01",
            "dependsOn": [],
            "type": "Microsoft.ContainerService/managedClusters",
            "location": "[parameters('location')]",
            "name": "[parameters('resourceName')]",
            "properties": {
                "kubernetesVersion": "[parameters('kubernetesVersion')]",
                "enableRBAC": "[parameters('enableRBAC')]",
                "dnsPrefix": "[parameters('dnsPrefix')]",
                "nodeResourceGroup": "[parameters('nodeResourceGroup')]",
                "agentPoolProfiles": [
                    {
                        "name": "${var.aks_agentpool_name}",
                        "osDiskSizeGB": "[parameters('osDiskSizeGB')]",
                        "count": 4,
                        "enableAutoScaling": true,
                        "minCount": 1,
                        "maxCount": 4,
                        "vmSize": "Standard_B2s",
                        "osType": "Linux",
                        "storageProfile": "ManagedDisks",
                        "type": "VirtualMachineScaleSets",
                        "mode": "System",
                        "maxPods": 210,
                        "availabilityZones": null,
                        "nodeTaints": [],
                        "enableNodePublicIP": false,
                        "tags": {}
                    }
                ],
                "networkProfile": {
                    "loadBalancerSku": "basic",
                    "networkPlugin": "[parameters('networkPlugin')]"
                },
                "disableLocalAccounts": "[parameters('disableLocalAccounts')]",
                "apiServerAccessProfile": {
                    "enablePrivateCluster": "[parameters('enablePrivateCluster')]"
                },
                "addonProfiles": {
                    "httpApplicationRouting": {
                        "enabled": "[parameters('enableHttpApplicationRouting')]"
                    },
                    "azurepolicy": {
                        "enabled": "[parameters('enableAzurePolicy')]"
                    },
                    "azureKeyvaultSecretsProvider": {
                        "enabled": "[parameters('enableSecretStoreCSIDriver')]",
                        "config": null
                    }
                }
            },
            "tags": {},
            "sku": {
                "name": "Basic",
                "tier": "Free"
            },
            "identity": {
                "type": "SystemAssigned"
            }
        }
    ],
    "outputs": {
        "controlPlaneFQDN": {
            "type": "string",
            "value": "[reference(concat('Microsoft.ContainerService/managedClusters/', parameters('resourceName'))).fqdn]"
        }
    }
}
DEPLOY

    deployment_mode = "Incremental"

}

output "aks_fqdn" {
  value = azurerm_template_deployment.aks-template.outputs["controlPlaneFQDN"]
}