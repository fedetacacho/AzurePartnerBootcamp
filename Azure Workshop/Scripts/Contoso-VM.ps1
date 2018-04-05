# 
#
# ----------------------------------------------------------------------------------------------------------------------
# | This PowerShell script will create an Azure Resource Manager Virtual Machine called CHQ01 in the Contoso-VNet      |
# |                                                                                                                    |
# | The Virtual Machine will be created in a Standard LRS Storage Account named contosohqservers.                      |
# | The Virtual Machine will have a public facing name of contoso-chq01.                                               |
# |                                                                                                                    |
# | The Virtual Machine will run the latest instance of Windows Server 2012 R2 Datacenter.                             |
# |                                                                                                                    |
# | The Virtual Machine will run on an A3 Standard Service Tier                                                        |
# |                                                                                                                    |
# | Cloud and Proud V2 with @AzureDan - daniel.baker@microsoft.com                                                     |
# |                                                                                                                    |
# ----------------------------------------------------------------------------------------------------------------------


# Configuring PowerShell with the latest Module Updates and Changing focus to ARM 

Install-Module AzureRM -Force
Import-Module AzureRM
Add-AzureRmAccount


# Set values for existing resource group and create a storage account (Remember Storage Account Name Must be Unique, use Test-AzureName -Storage <Proposed storage account name> to check)

$rgName="ContosoHQ"
$locName="Central US"
$saName="contosohqserverss"
$saType="Standard_LRS"
New-AzureRmStorageAccount -Name $saName -ResourceGroupName $rgName –Type $saType -Location $locName


# Set the existing virtual network and subnet index

$vnetName="Contoso-VNet"
$subnetIndex=0
$vnet=Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName


# Create the NIC

$nicName="CHQ01-NIC"
$domName="contoso-chq01"
$pip=New-AzureRmPublicIpAddress -Name $nicName -ResourceGroupName $rgName -DomainNameLabel $domName -Location $locName -AllocationMethod Dynamic
$nic=New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[$subnetIndex].Id -PublicIpAddressId $pip.Id


# Specify the name and size of the Virtual Machine

$vmName="CHQ01"
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
$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName
$osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage
New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $vm
