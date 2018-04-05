Login-AzureRmAccount
Get-AzureRmSubscription
Select-AzureRmSubscription -SubscriptionId "99b0d0fa-87c6-4a18-bd19-d8b6488f0240"
Get-AzureRmStorageAccount
$rgName = "Compute"
$urlOfUploadedImageVhd = "https://azuredanvmdisks.blob.core.windows.net/vhds/windows10.vhd"
Add-AzureRmVhd -ResourceGroupName $rgName -Destination $urlOfUploadedImageVhd -LocalFilePath "C:\VMs\W10.vhd"