# 
#
# ----------------------------------------------------------------------------------------------------------------------
# |                                                                                                                    |
# | This PowerShell script will create an Azure Resource Manager Virtual Network named Northwind-VNet with two Subnets |
# | and populate with a Virtual Machine running Windows Server 2012R2 Datacenter named NWHQ01                          |
# |                                                                                                                    |
# |  This is used for cross sub connectivity in session 1 of Cloud and Proud                                           |
# |                                                                                                                    |
# |                                                                                                                    |
# | Cloud and Proud V2 with @AzureDan - daniel.baker@microsoft.com                                                     |
# |                                                                                                                    |
# ----------------------------------------------------------------------------------------------------------------------


 
# Configuring PowerShell with the latest Module Updates and Changing focus to ARM 

Install-Module AzureRM -Force
Import-Module AzureRM
Add-AzureRmAccount


# Setting the Variables

$VNetName  = "Northwind-VNet"
$SubName = "Production"
$GWSubName = "GatewaySubnet"
$VNetPrefix = "192.168.200.0/24"
$SubPrefix = "192.168.200.0/25"
$GWSubPrefix = "192.168.200.128/29"
$RG = "Northwind"
$Location = "Central US"
$GWName = "NorthwindGateway"
$GWIPName = "NORTHGWIP"
$GWIPconfName = "gwipconf"


# Creating the Resource Group: 

New-AzureRmResourceGroup -Name $RG -Location $Location


# Creating the Subnets: 

$sub = New-AzureRmVirtualNetworkSubnetConfig -Name $SubName -AddressPrefix $SubPrefix
$gwsub = New-AzureRmVirtualNetworkSubnetConfig -Name $GWSubName -AddressPrefix $GWSubPrefix


# Creating the Virtual Network based on the Subnets: 


$vnet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $RG -Location $Location -AddressPrefix $VNetPrefix -Subnet $sub, $gwsub


# Adding a public IP address to the Gateway subnet: 

$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet
$pip = New-AzureRmPublicIpAddress -Name $GWIPName -ResourceGroupName $RG -Location $Location -AllocationMethod Dynamic
$ipconf = New-AzureRmVirtualNetworkGatewayIpConfig -Name $GWIPconfName -Subnet $subnet -PublicIpAddress $pip


# Creating the Virtual Network Gateway: This would be a good time to take a break :) 

New-AzureRmVirtualNetworkGateway -Name $GWName -ResourceGroupName $RG -Location $Location -IpConfigurations $ipconf -GatewayType Vpn -VpnType RouteBased -EnableBgp $false -GatewaySku Standard -VpnClientAddressPool $VPNClientAddressPool


# Create a storage account (Remember Storage Account Name Must be Unique, use Test-AzureName -Storage <Proposed storage account name> to check)

$saName="northwindhqserverss"
$saType="Standard_LRS"
New-AzureRmStorageAccount -Name $saName -ResourceGroupName $RG –Type $saType -Location $Location


# Set the existing virtual network and subnet index

$subnetIndex=0
$vnet=Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $RG


# Create the NIC

$nicName="NWHQ01-NIC"
$domName="northwind-nwhq01"
$pip=New-AzureRmPublicIpAddress -Name $nicName -ResourceGroupName $RG -DomainNameLabel $domName -Location $Location -AllocationMethod Dynamic
$nic=New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $RG -Location $Location -SubnetId $vnet.Subnets[$subnetIndex].Id -PublicIpAddressId $pip.Id


# Specify the name and size of the Virtual Machine

$vmName="NWHQ01"
$vmSize="Standard_A3"
$vm=New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize


# Specify the image and local administrator account, and then add the NIC

$pubName="MicrosoftWindowsServer"
$offerName="WindowsServer"
$skuName="2012-R2-Datacenter"
$cred=Get-Credential -Message "Type the name and password of the local administrator account."
$vm=Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AzureRmVMSourceImage -VM $vm -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"
$vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id


# Specify the OS disk name and create the VM

$diskName="OSDisk"
$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $RG -Name $saName
$osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage
New-AzureRmVM -ResourceGroupName $RG -Location $Location -VM $vm
