

Login-Azure 

# Create an AZURE Resoruce Group.
Create-ResourceGroup -Name Agile2018_RG -Location "EASTUS2" | 
    # Create a Virtual Network

    Create-VirtualNetwork -Name "cust1Vnet" -AddressSpace  192.168.0.0/16 | 
    
        # Create a Sub Network
        Create-SubNetwork -Name "frontEndSubNet" -AddressSpace 192.168.1.0/24 |
    
            # Create Backend SubNet
            Create-SubNetwork -Name "backEndSubNet" -AddressSpace 192.168.2.0/24 |
    
                # Create NSG
                Create-NetworkSecurityGroup -Name "NSG-FrontEnd" -rgName "Agile2018_RG"
    
                    # Create NSG Rules
                    $rules = Create-NSGRule -Name "Allow_Http" -Port 80 -Priority 100 -SourceAddressPrefix Internet -Access Allow | Create-NSGRule -Name "Allow_RDP" -SourceAddressPrefix Internet -Port 3389 -Priority 101 -Access Allow
                    $cred = Get-Credential
    
                        # Add Network Security Rule
                        Add-NetworkSecurityRule -NsgName "NSG-FrontEnd" -RGName "Agile2018_RG" -Rules $rules |
    
                            # Associate NDG subnet
                            Associate-NSGtoSubNet -RGName "Agile2018_RG" -SubNetName "frontEndSubNet" -NetworkPrefix 192.168.1.0/24 |
    
                                # Create Availability Set
                                Create-AvailabilitySet -Name demoAvailabilitySet  | 
    
                                # Create First Widows VM
                                Create-WindowsVM -VMName "vmweb1" -RGName "Agile2018_RG" -StorageAccountName "storageagile2018" -NSGName "NSG-FrontEnd" -SubNetName "frontEndSubNet" -SQLServer "No" |

                                #Install-IIS
                                Install-IIS -VMName "vmweb1" | 

                                # Create Second Widows VM
                                Create-WindowsVM -VMName "vmweb2" -RGName "Agile2018_RG" -StorageAccountName "storageagile2018" -NSGName "NSG-FrontEnd" -SubNetName "frontEndSubNet" -SQLServer "No" |

                                    #Install-IIS
                                Install-IIS -VMName "vmweb2" 

                                # Create a public IP Address
                                Create-StaticIPAddress -RGName "Agile2018_RG" | 

                                # Create Load Balancer
                                Create-LoadBalancer -Name NRPAgile2018-LB -RGName "Agile2018_RG" -FrontEndAddresspoolName  LB-Frontend -BackEndAddresspoolName LB-backend | 

                                # Set NIC configuration
                                Set-VMNICConfiguration -VMName "vmweb1" -BackEndAddresspoolName LB-backend | Set-VMNICConfiguration -VMName "vmweb2" -BackEndAddresspoolName LB-backend

                                # Create NSG for SQL
                                Create-NetworkSecurityGroup -Name "NSG-BackEnd" -rgName  "Agile2018_RG"

                                $Backedrules = Create-NSGRule -Name "Allow_SQL" -Port 1433 -Priority 200 -SourceAddressPrefix "192.168.1.0/24" -Access Allow  | Create-NSGRule -Name "Block_Internet" -Port * -Priority 201 -SourceAddressPrefix "*" -Access Deny
                                # Add Network Security Rule
                                Add-NetworkSecurityRule -NsgName "NSG-BackEnd" -RGName "Agile2018_RG" -Rules $Backedrules 
    
                                 # Create Second Widows VM
                                Create-WindowsVM -VMName "vmsqlserver" -RGName "Agile2018_RG" -StorageAccountName "storageagile2018" -NSGName "NSG-BackEnd" -SubNetName "backEndSubNet" -SQLServer "Yes"