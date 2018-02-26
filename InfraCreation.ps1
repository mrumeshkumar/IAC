
# Login
#'Pay-As-You-Go-Action-Pack'
function Login-Azure{

    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $SubscriptionName
    )
    try {
           Login-AzureRmAccount
           Set-AzureRmContext -Subscription $SubscriptionName

 
    } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
}

function Create-ResourceGroup {

    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $Name,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $Location
    )

    $ErrorActionPreference = 'Stop'
  
    try {
            # Check if already exists
            $rg = Get-AzureRmResourceGroup -Name $Name -ErrorAction SilentlyContinue

            if(!$rg)
            {
                # Create a RM
                $rg = New-AzureRmResourceGroup -Name $Name -Location $Location -ErrorAction $ErrorActionPreference 
                
                #Success Message
                Write-Host 'Resource Group created successfully!' -ForegroundColor Green
            }
            else
            {
                #Success Message
                Write-Host 'Resource Group already created and available' -ForegroundColor Green
            }

            return $rg
 
    } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
}

#cust1Vnet \ 192.168.0.0/16
function Create-VirtualNetwork {

   [cmdletbinding()]
   Param
   ( 
        [Parameter(ValueFromPipeline)] 
        $rg,
        [Parameter(Mandatory=$true, Position=1)]
        $Name,
        [Parameter(Mandatory=$true, Position=2)]
        $AddressSpace
   ) 
            
    $ErrorActionPreference = 'Stop'

    try {
             
            $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue

            if(!$vnet )
            {
                # Create a new Virtual Network
                $vnet = New-AzureRmVirtualNetwork -ResourceGroupName $rg.ResourceGroupName -Name $Name -AddressPrefix $AddressSpace -Location $rg.Location -Verbose
                
                #Success Message
                Write-Host 'Virtual Network created successfully!' -ForegroundColor Green
            }
            else
            {
                #Success Message
                Write-Host 'Virtual Network already created and available' -ForegroundColor Green
            }

            return $vnet

    } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
}

#Name: frontEndSubNet\192.168.1.0/24, backEndSubNet\192.168.2.0/24
function Create-SubNetwork {

   [cmdletbinding()]
   Param
   ( 
        [Parameter(ValueFromPipeline)] 
        $vnet,
        [Parameter(Mandatory=$true, Position=1)]
        $Name,
        [Parameter(Mandatory=$true, Position=2)]
        $AddressSpace
   ) 
            
    $ErrorActionPreference = 'Stop'
           
            $subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $Name -VirtualNetwork $vnet -ErrorAction SilentlyContinue  
    try {

            if(!$subnet)
            {
                # Add a FrontEnd SubNet to Virtual Network 
                $subnet = Add-AzureRmVirtualNetworkSubnetConfig -Name $Name -VirtualNetwork $vnet -AddressPrefix $AddressSpace
                Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
                     
                #Success Message
                Write-Host 'Subnet created successfully!' -ForegroundColor Green
            }
            else
            {
                #Success Message
                Write-Host 'Subnet already created and available' -ForegroundColor Green
            }

            return $vnet

    } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
}

#"NSG-FrontEnd"
function Create-NetworkSecurityGroup {

   [cmdletbinding()]
   Param
   ( 
        [Parameter(ValueFromPipeline)] 
        $vnet,
        [Parameter(Mandatory=$true, Position=1)]
        $RGName,
        [Parameter(Mandatory=$true, Position=2)]
        $Name
   ) 
           
        try {

             # Check if already exists
            $rg = Get-AzureRmResourceGroup -Name $RGName

             # Check if already exists
            $nsg = Get-AzureRmNetworkSecurityGroup -Name $Name -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue

            if(!$nsg)
            {
                # Add to a NSG
                $nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -Name $Name 
                     
                #Success Message
                Write-Host 'NSG created successfully!' -ForegroundColor Green
            }
            else
            {
                #Success Message
                Write-Host 'NSG already created and available' -ForegroundColor Green
            }

            $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rg.ResourceGroupName
            Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

            return $nsg

    } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
}

function Create-NSGRule {

   [cmdletbinding()]
   Param
   ( 
        [Parameter(ValueFromPipeline)] 
        [System.Collections.ArrayList]$Rules,
        [Parameter(Mandatory=$true, Position=1)]
        $Name,
        [Parameter(Mandatory=$true, Position=2)]
        $Port,
        [Parameter(Mandatory=$true, Position=3)]
        [int]$Priority,
        [Parameter(Mandatory=$true, Position=4)]
        $SourceAddressPrefix,
        [Parameter(Mandatory=$true, Position=5)]
        $Access


   )   
    
    try {
             
           $rule=  New-AzureRmNetworkSecurityRuleConfig -Name $Name -Description $Name `
                -Access $Access -Protocol Tcp -Direction Inbound `
                -SourceAddressPrefix $SourceAddressPrefix -SourcePortRange * `
                -DestinationAddressPrefix * -DestinationPortRange $Port -Priority $Priority

            Write-Host 'NSG Rule created and available' -ForegroundColor Green
           
            if($Rules.Count -eq 0) {
                   $Rules = @()
            }

            $Rules.Add($rule)
             
            return $Rules

    } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
}

function Add-NetworkSecurityRule {
   [cmdletbinding()]
   Param
   ( 
        [Parameter(Mandatory=$true, Position=1)]
        $RGName,
        [Parameter(Mandatory=$true, Position=2)]
        $NsgName,
        [Parameter(Mandatory=$true, Position=3)]
        [System.Collections.ArrayList]$Rules
   ) 
           
        try {
            
            $rg = Get-AzureRmResourceGroup -Name $RGName
            
            $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rg.ResourceGroupName

             # Check if rule already exists
            $nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rg.ResourceGroupName

            # Add to a NSG
            New-AzureRmNetworkSecurityGroup -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -Name $NsgName -SecurityRules $Rules[1],$Rules[2] -Force
                     
            #Success Message
            Write-Host 'Rule added to NSG successfully!' -ForegroundColor Green
            
            Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

            return $nsg

    } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
}

#frontEndSubNet  -AddressPrefix 192.168.1.0/24
function Associate-NSGtoSubNet {
   [cmdletbinding()]
   Param
   ( 
        [Parameter(ValueFromPipeline)] 
        $nsg ,
        [Parameter(Mandatory=$true, Position=1)]
        $RGName,
        [Parameter(Mandatory=$true, Position=2)]
        $SubNetName,
        [Parameter(Mandatory=$true, Position=3)]
        $NetworkPrefix

   ) 
           
        try {
            
            $rg = Get-AzureRmResourceGroup -Name $RGName
            
            $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rg.ResourceGroupName

            # Associate the NSG created above to the FrontEnd subnet
            Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name frontEndSubNet -AddressPrefix $NetworkPrefix -NetworkSecurityGroup $nsg
                     
            #Success Message
            Write-Host 'NSG associated to a subnet' -ForegroundColor Green
            
            Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

            return $vnet

    } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
}

#demoAvailabilitySet
function Create-AvailabilitySet {
   [cmdletbinding()]
   Param
   ( 
        [Parameter(ValueFromPipeline)] 
        $vnet,
        [Parameter(Mandatory=$true, Position=1)]
        $Name
   ) 
           
       try {

             # Check if already exists
            $availset = Get-AzureRmAvailabilitySet -Name $Name -ResourceGroupName $vnet.ResourceGroupName -ErrorAction SilentlyContinue

            if(!$availset)
            {
                # Create Availability Set
                $availset = New-AzureRmAvailabilitySet `
                               -Location $vnet.Location `
                               -Name $Name `
                               -ResourceGroupName $vnet.ResourceGroupName `
                               -sku aligned `
                               -PlatformFaultDomainCount 2 `
                               -PlatformUpdateDomainCount 3
                     
                #Success Message
                Write-Host 'Availability Set created successfully!' -ForegroundColor Green
            }
            else
            {
                #Success Message
                Write-Host 'Availability Set already created and available' -ForegroundColor Green
            }

            return $availset

    } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
}

#demoAvailabilitySet
function Create-WindowsVM {
   [cmdletbinding()]
   Param
   ( 
        [Parameter(ValueFromPipeline)] 
        $availset,
        [Parameter(Mandatory=$true, Position=1)]
        $VMName,
        [Parameter(Mandatory=$true, Position=2)]
        $RGName,
        [Parameter(Mandatory=$true, Position=3)]
        $StorageAccountName,
        [Parameter(Mandatory=$true, Position=4)]
        $NSGName,
        [Parameter(Mandatory=$true, Position=5)]
        $SubNetName,
        [Parameter(Mandatory=$true, Position=6)]
        $SQLServer="No"
   ) 
           
       try {

            $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $RGName 

             # Check if already exists
            $vm = Get-AzureRmVM -Name $VMName -ResourceGroupName $vnet.ResourceGroupName -ErrorAction SilentlyContinue

            $subnetId = Get-AzureRmVirtualNetworkSubnetConfig -Name $SubNetName -VirtualNetwork $vnet
            $nsg = Get-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $vnet.ResourceGroupName

            if(!$vm)
            {
                #Create a storage account
                $storage= Get-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $vnet.ResourceGroupName -ErrorAction SilentlyContinue
                
                if(!$storage) {
                   $vm = New-AzureRmStorageAccount -Name $StorageAccountName -kind Storage -ResourceGroupName $vnet.ResourceGroupName -Type Standard_LRS -Location $vnet.Location
                }
                
                $pip = New-AzureRmPublicIpAddress `
                            -ResourceGroupName $vnet.ResourceGroupName `
                            -Location $vnet.Location `
                            -Name $VMName"_pip2" `
                            -AllocationMethod Dynamic `
                            -DomainNameLabel $VMName"2018"

                $nic = New-AzureRmNetworkInterface `
                    -Name $VMName"_nic" `
                    -ResourceGroupName $vnet.ResourceGroupName `
                    -Location $vnet.Location `
                    -SubnetId $subnetId.Id `
                    -PublicIpAddressId $pip.Id `
                    -NetworkSecurityGroupId $nsg.Id

                
                if($availset) {
                    $vmconfig = New-AzureRmVMConfig -VMName $VMName -VMSize Standard_A0 -AvailabilitySetId $availset.Id | `
                        Set-AzureRmVMOperatingSystem -ComputerName $VMName -Credential $cred -Windows -EnableAutoUpdate -ProvisionVMAgent | `
                        Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer  -Skus 2016-Datacenter -Version latest ` |
                        Set-AzureRmVMOSDisk -StorageAccountType StandardLRS -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite -Name $VMName"-OS" ` |
                        Set-AzureRmVMBootDiagnostics -Enable -ResourceGroupName $vnet.ResourceGroupName -StorageAccountName $StorageAccountName
                }
                else {

                    if($SQLServer="No"){
                         $vmconfig = New-AzureRmVMConfig -VMName $VMName -VMSize Standard_A0 | `
                            Set-AzureRmVMOperatingSystem -ComputerName $VMName -Credential $cred -Windows -EnableAutoUpdate -ProvisionVMAgent | `
                            Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer  -Skus 2016-Datacenter -Version latest ` |
                            Set-AzureRmVMOSDisk -StorageAccountType StandardLRS -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite -Name $VMName"-OS" ` |
                            Set-AzureRmVMBootDiagnostics -Enable -ResourceGroupName $vnet.ResourceGroupName -StorageAccountName $StorageAccountName
                    }
                    else {
                        $VMConfig = New-AzureRmVMConfig -VMName $VMName -VMSize Standard_F1 | `
                            Set-AzureRmVMOperatingSystem -Windows -ComputerName $VMName -Credential $Cred -ProvisionVMAgent -EnableAutoUpdate | `
                            Set-AzureRmVMSourceImage -PublisherName "MicrosoftSQLServer" -Offer "SQL2017-WS2016" -Skus "SQLDEV" -Version "latest"
                    }   

                }

                $vmconfig = Add-AzureRmVMNetworkInterface -VM $vmconfig -Id $nic.Id

                 $vm =New-AzureRmVM `
                    -ResourceGroupName $vnet.ResourceGroupName   `
                    -Location $vnet.Location `
                    -VM $vmconfig
                
                Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
                                       
                #Success Message
                Write-Host 'VM created successfully!' -ForegroundColor Green
            }
            else
            {
                #Success Message
                Write-Host 'VM already created and available' -ForegroundColor Green
            }

            return $availset

    } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
}


function Install-IIS {
   [cmdletbinding()]
   Param
   ( 
        [Parameter(ValueFromPipeline)] 
        $availset,
        [Parameter(Mandatory=$true, Position=2)]
        $VMName
   ) 
           
        try {
            
            $rg = Get-AzureRmResourceGroup -Name $availset.ResourceGroupName
           
            # Install IIS
            $PublicSettings = '{"commandToExecute":"powershell Add-WindowsFeature Web-Server"}'

            Set-AzureRmVMExtension -ExtensionName "IIS" -ResourceGroupName $rg.ResourceGroupName -VMName $VMName `
                              -Publisher "Microsoft.Compute" -ExtensionType "CustomScriptExtension" -TypeHandlerVersion 1.4 `
                              -SettingString $PublicSettings -Location $rg.Location
                                                   
            #Success Message
            Write-Host 'IIS Installed successfully!' -ForegroundColor Green

            return $availset

    } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
}

function Create-StaticIPAddress {
   [cmdletbinding()]
   Param
   ( 
        [Parameter(Mandatory=$true, Position=1)]
        $RGName
   ) 
           
        try {
            
            $rg = Get-AzureRmResourceGroup -Name $RGName
           
            # Create a Public IP Address
            $publicIP = New-AzureRmPublicIpAddress -Name PublicIp -ResourceGroupName  $rg.ResourceGroupName -Location $rg.Location -AllocationMethod Static -DomainNameLabel loadbalancercustwebapp -Force
                                                   
            #Success Message
            Write-Host 'Public Ip created successfully!' -ForegroundColor Green

            return $publicIP

    } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
}


#NRPAgile2018-LB / LB-Frontend / LB-backend
function Create-LoadBalancer {
   [cmdletbinding()]
   Param
   ( 
        [Parameter(ValueFromPipeline)] 
        $publicIP,
        [Parameter(Mandatory=$true, Position=1)]
        $Name,
        [Parameter(Mandatory=$true, Position=2)]
        $RGName,
        [Parameter(Mandatory=$true, Position=3)]
        $FrontEndAddresspoolName,
        [Parameter(Mandatory=$true, Position=4)]
        $BackEndAddresspoolName
   ) 
           
       try {

            $rg = Get-AzureRmResourceGroup -Name $RGName

             # Check if already exists
            $LB = Get-AzureRmLoadBalancer -Name $Name -ResourceGroupName $RGName -ErrorAction SilentlyContinue

            if(!$LB)
            {
                
                # Create a front-end IP pool named LB-Frontend that uses the PublicIp resource.
                $frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name $FrontEndAddresspoolName -PublicIpAddress $publicIP

                # Create NAT rules
                $inboundNATRule1= New-AzureRmLoadBalancerInboundNatRuleConfig -Name RDP1 -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 3441 -BackendPort 3389
                $inboundNATRule2= New-AzureRmLoadBalancerInboundNatRuleConfig -Name RDP2 -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 3442 -BackendPort 3389
                
                # create health probe
                $healthProbe = New-AzureRmLoadBalancerProbeConfig -Name HealthProbe -Protocol Tcp -Port 80 -IntervalInSeconds 15 -ProbeCount 2

                # Create backend address pool
                $beaddresspool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name $BackEndAddresspoolName

                # Create Load Balancer Config
                $lbrule = New-AzureRmLoadBalancerRuleConfig -Name HTTP -FrontendIpConfiguration $frontendIP -BackendAddressPool  $beAddressPool -Probe $healthProbe -Protocol Tcp -FrontendPort 80 -BackendPort 80

                # CREATE the Load Balancer
                $LB = New-AzureRmLoadBalancer -ResourceGroupName $rg.ResourceGroupName -Name $Name -Location $rg.Location -FrontendIpConfiguration $frontendIP -InboundNatRule $inboundNATRule1,$inboundNatRule2 -LoadBalancingRule $lbrule -BackendAddressPool $beAddressPool -Probe $healthProbe

                $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $RGName
                Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
        
                Set-AzureRmLoadBalancer -LoadBalancer $LB

                #Success Message
                Write-Host 'Load Balancer created successfully!' -ForegroundColor Green
            }
            else
            {
                #Success Message
                Write-Host 'Load Balancer already created and available' -ForegroundColor Green
            }

            return $LB

    } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
}



#demoAvailabilitySet
function Set-VMNICConfiguration{
   [cmdletbinding()]
   Param
   ( 
        [Parameter(ValueFromPipeline)] 
        $LB,
        [Parameter(Mandatory=$true, Position=2)]
        $VMName,
        [Parameter(Mandatory=$true, Position=3)]
        $BackEndAddresspoolName
   ) 
           
       try {

                $beaddresspool=Get-AzureRmLoadBalancerBackendAddressPoolConfig -name $BackEndAddresspoolName -LoadBalancer $LB

                # Get the existing NIC - First VM
                $nic =get-azurermnetworkinterface -name $VMName"_nic" -ResourceGroupName $LB.ResourceGroupName
                $nic.IpConfigurations[0].LoadBalancerBackendAddressPools=$beaddresspool

                Set-AzureRmNetworkInterface -NetworkInterface $nic
                
                Set-AzureRmLoadBalancer -LoadBalancer $LB

                return $LB
                                     
                #Success Message
                Write-Host 'NIC Configuration Set successfully!' -ForegroundColor Green
          
    } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
}