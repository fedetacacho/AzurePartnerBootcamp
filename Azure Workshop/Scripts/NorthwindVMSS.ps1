# Configuring PowerShell with the latest Module Updates and Changing focus to ARM 

Install-Module AzureRM -Force
Import-Module AzureRM
Add-AzureRmAccount


# Setting the Variables
$locName = "West Europe"
$rgName = "NorthwindVMSS"
$saName = "nevmssdisk"
$saType = "Standard_LRS"
$subName = "NorthwindVMs"
$netName = "NorthwindTraders"
$domName = "nwtradersvmss"
$pipName = "nwtpip"
$nicName = "nwtnic"
$ipName = "nwtipc"
$vmssConfig = "NorthwindScaleSet"
$computerName = "nwtvm"
$adminName = "Student"
$adminPassword = "Pa$$w0rd1234"
$storeProfile = "nwtvmssstore"
$imagePublisher = "MicrosoftWindowsServer"
$imageOffer = "WindowsServer"
$imageSku = "2012-R2-Datacenter"
$vmssName = "NorthwindScaleSet"


# Create the Resource Group
New-AzureRmResourceGroup -Name $rgName -Location $locName

# Create the Storage Account
New-AzureRmStorageAccount -Name $saName -ResourceGroupName $rgName –Type $saType -Location $locName

# Create the Subnet
$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subName -AddressPrefix 10.0.0.0/24

# Create the Virtual Network
$vnet = New-AzureRmVirtualNetwork -Name $netName -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $subnet

# Create the public IP address
$pip = New-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic -DomainNameLabel $domName

# Create the network interface
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id

# Create the IP configuration
$ipConfig = New-AzureRmVmssIpConfig -Name $ipName -LoadBalancerBackendAddressPoolsId $null -SubnetId $vnet.Subnets[0].Id

# Create the configuration for the scale set
$vmss = New-AzureRmVmssConfig -Location $locName -SkuCapacity 3 -SkuName "Standard_A2" -UpgradePolicyMode "manual"

# Add the network interface configuration to the scale set configuration
Add-AzureRmVmssNetworkInterfaceConfiguration -VirtualMachineScaleSet $vmss -Name $vmssConfig -Primary $true -IPConfiguration $ipConfig

# Create the operating system profile
Set-AzureRmVmssOsProfile -VirtualMachineScaleSet $vmss -ComputerNamePrefix $computerName -AdminUsername $adminName -AdminPassword $adminPassword

# Create a container and populate variable with blob url
$vhdContainers = @("https://nevmssdisk.blob.core.windows.net/vhds")

# Create the storage profile
Set-AzureRmVmssStorageProfile -VirtualMachineScaleSet $vmss -ImageReferencePublisher $imagePublisher -ImageReferenceOffer $imageOffer -ImageReferenceSku $imageSku -ImageReferenceVersion "latest" -Name $storeProfile -VhdContainer $vhdContainers -OsDiskCreateOption "FromImage" -OsDiskCaching "None"  

# Create the scale set
New-AzureRmVmss -ResourceGroupName $rgName -Name $vmssName -VirtualMachineScaleSet $vmss