# 
#
# ----------------------------------------------------------------------------------------------------------------------
# | Required Files                                                                                                     |
# |   Makecert.exe                                                                                                     |
# |                                                                                                                    |
# | This PowerShell script will create an Azure Resource Manager Virtual Network named Contoso-VNet with two Subnets.  |
# |                                                                                                                    |
# | The first Subnet (Named Production) will be used for Virtual Machines later in this course.                        |
# | The Second Subnet (ContosoGateway) will be used as an endpoint for incoming connections.                           |
# |                                                                                                                    |
# | The Gateway will have a Public Interface                                                                           |
# |                                                                                                                    |
# | The Gateway will also host a VPN Client Address pool 192.168.20.0/25 allowing 127 External Client Connections      |
# |                                                                                                                    |
# |                                                                                                                    |
# | Note                                                                                                               |
# | ***** Before Running this script it is important to copy the Makecert.exe file into the C:\Windows\System32 Folder |
# |                                                                                                                    |
# | Cloud and Proud V2 with @AzureDan - daniel.baker@microsoft.com                                                     |
# |                                                                                                                    |
# ----------------------------------------------------------------------------------------------------------------------


 
# Configuring PowerShell with the latest Module Updates and Changing focus to ARM 

Install-Module AzureRM -Force
Import-Module AzureRM
Add-AzureRmAccount


# Setting the Variables

$VNetName  = "Contoso-VNet"
$SubName = "Production"
$GWSubName = "GatewaySubnet"
$VNetPrefix = "192.168.10.0/24"
$SubPrefix = "192.168.10.0/25"
$GWSubPrefix = "192.168.10.128/29"
$VPNClientAddressPool = "192.168.20.0/25"
$RG = "ContosoHQ"
$Location = "Central US"
$GWName = "CHQGateway"
$GWIPName = "CHQGWIP"
$GWIPconfName = "gwipconf"
$P2SRootCertName = "CHQRoot2.cer"


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


# Creating The Root and Client PKI Certificates for P2S Authentication - If you havent copied Makecert.exe to C:\Windows\System32 then this will fail.  

cd 'C:\Cloud and Proud V2 Live Delivery Files'
makecert.exe -sky exchange -r -n "CN=CHQRoot" -pe -a sha256 -len 2048 -ss My "CHQRoot.cer"
makecert.exe -n "CN=CHQClient" -pe -sky exchange -m 96 -ss My -in "CHQRoot" -is my -a sha256
certutil -encode CHQRoot.cer CHQRoot2.cer


# Getting the certificate contents and removing unnecessary headers

$Text = Get-Content -Path "C:\Cloud and Proud V2 Live Delivery Files\CHQRoot2.cer"
$CertificateText = for ($i=1; $i -lt $Text.Length -1 ; $i++){$Text[$i]}


# Uploading the root certificate to the Virtual Gateway: 

Add-AzureRmVpnClientRootCertificate -PublicCertData ($CertificateText | out-string) -ResourceGroupName $RG -VirtualNetworkGatewayName $GWName -VpnClientRootCertificateName $P2SRootCertName


# Creating a download URL for the Windows VPN Client - simply copy and paste into a browser to download.

Get-AzureRmVpnClientPackage -ResourceGroupName $RG -VirtualNetworkGatewayName $GWName -ProcessorArchitecture Amd64
