Import-Module "./Module.psm1"

$deployPath = Convert-Path .
$excelSheet = $deployPath + "/AzureEnv.xlsx"

#copy service fabric template from template forlder to current folder.
$sfARMTemplate = "../../arm/ServiceFabric/SF-1NT-Linux.json"
Copy-Item -Path $sfARMTemplate -Destination "./SFTemplate.json"
$sfARMTemplate = "$deployPath/SFTemplate.json"

# Service Fabric is not available in AzBB. We use use our own ARM Template to Generate a Parameter Json. 
$sfSheet = Import-Excel -Path $excelSheet -WorksheetName ServiceFabric

# read input parameter
$RG = $sfSheet[0].C; $Location = $sfSheet[0].D
$clusterDnsName = $sfSheet[1].C
$nt0InstanceCount = $sfSheet[2].C; $vmNodeType0Size = $sfSheet[2].D
$sfLogStorageAccount = $sfSheet[3].C; $LogStorAccountSKU = $sfSheet[3].D
$pipName = $sfSheet[4].C; $InternetAccessPort1 = $sfSheet[4].D; $InternetAccessPort2 = $sfSheet[4].E
$vNetResourceGroup = $sfSheet[5].C; $vNetName = $sfSheet[5].D; $subnetName = $sfSheet[5].E

$adminUsername = $sfSheet[6].C
$keyvaultRG = $sfSheet[6].D
$keyvault = $sfSheet[6].E
$secret = $sfSheet[6].F
$envSheet = Import-Excel -Path $excelSheet -WorksheetName Environment -DataOnly
$subscriptionId = $envSheet[0].SubscriptionID
$adminpassword = @{ reference = @{keyVault = @{id = "/subscriptions/$subscriptionId/resourceGroups/$keyvaultRG/providers/Microsoft.KeyVault/vaults/$keyvault"}; secretName = $secret} }

$securityLevel = $sfSheet[7].C; $sourceVaultValue = $sfSheet[7].D; $certificateUrlValue= $sfSheet[7].E; $certificateThumbprint= $sfSheet[7].F

$parameterFile = @{
  contentVersion = "1.0.0.0";
  parameters = @{
                    clusterDnsName = @{
                        value = $clusterDnsName
                    }
                    adminUsername = @{
                        value = $adminUsername
                    }
                    adminPassword = $adminPassword
                    certificateThumbprint = @{
                        value = $certificateThumbprint
                    }
                    certificateUrlValue = @{
                        value = $certificateUrlValue
                    }
                    sourceVaultValue = @{
                        value = $sourceVaultValue
                    }
                    pipName = @{
                        value = $pipName
                    }
                    vNetResourceGroup = @{
                        value = $vNetResourceGroup
                    }
                    vNetName = @{
                        value = $vNetName
                    }
                    subnetName = @{ 
                        value = $subnetName
                    }
                    sfLogStorageAccount = @{
                        value = $sfLogStorageAccount
                    }
            }
}
$parameterFile = ConvertTo-Json -InputObject $parameterFile -Depth 10
$parameterFile = $parameterFile.Replace("null", "")
$parameterFileName = "arm-sf-$clusterDnsName-Param.json"

$parameterFile | Out-File -Encoding utf8 "$deployPath/$parameterFileName"
"### azure service fabric provision command" | Out-File -Encoding utf8 "$deployPath/az-sf-create-cmd.bat"
"az group deployment create -g " + $RG + " --template-file " + $sfARMTemplate + " --parameters @$deployPath/$parameterFileName" | Out-File -Encoding utf8 -Append "$deployPath/az-sf-create-cmd.bat"

