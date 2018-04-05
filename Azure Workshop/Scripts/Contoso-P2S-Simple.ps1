# Configuring PowerShell with the latest Module Updates and Changing focus to ARM 

#Install-Module AzureRM -Force
Import-Module AzureRM
Add-AzureRmAccount

Select-AzureRmSubscription -SubscriptionName "Visual Studio Enterprise"

# Setting the Variables

$RG = "ParaBorrar"
$GWName = "DemoGW"
$GWIPName = "DemoGW-ip"
$P2SRootCertName = "DemoRoot2.cer"


# Creating The Root and Client PKI Certificates for P2S Authentication - If you havent copied Makecert.exe to C:\Windows\System32 then this will fail.  

cd 'C:\Nexsys CSP Workshop'
makecert.exe -sky exchange -r -n "CN=DemoRoot" -pe -a sha256 -len 2048 -ss My "DemoRoot.cer"
makecert.exe -n "CN=DemoClient" -pe -sky exchange -m 96 -ss My -in "DemoRoot" -is my -a sha256
certutil -encode DemoRoot.cer DemoRoot2.cer


# Getting the certificate contents and removing unnecessary headers

$Text = Get-Content -Path "C:\Cloud and Proud V2 Live Delivery Files\DemoRoot2.cer"
$CertificateText = for ($i=1; $i -lt $Text.Length -1 ; $i++){$Text[$i]}


# Uploading the root certificate to the Virtual Gateway: 

Add-AzureRmVpnClientRootCertificate -PublicCertData ($CertificateText | out-string) -ResourceGroupName $RG -VirtualNetworkGatewayName $GWName -VpnClientRootCertificateName $P2SRootCertName


# Creating a download URL for the Windows VPN Client - simply copy and paste into a browser to download.

Get-AzureRmVpnClientPackage -ResourceGroupName $RG -VirtualNetworkGatewayName $GWName -ProcessorArchitecture Amd64
