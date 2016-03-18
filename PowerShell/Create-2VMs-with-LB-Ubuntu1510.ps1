##############################################################################
# name:
# Create-VirtualMachine.ps1
#
# description:
# create virtual machine
#
##############################################################################
# variables
#
Param (
  [switch]$Help,
  [string]$Name,
  [ValidateSet("Standard_A1","Standard_A2","Standard_A3","Standard_A4","Standard_D1","Standard_D2","Standard_D3","Standard_D4")][string]$Size,
  [string]$StorageAccount,
  [string]$Basename,
  [ValidateSet("japaneast","japanwest","eastasia","southeastasia")][string]$Location
)

##############################################################################
# libraries
#
function Print-Log( [string] $msg ) {
  if ( $msg -ne '') {
    $timestamp = Get-Date -format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[$timestamp] $msg"
  }
}

##############################################################################
# start
# 
if (( $Help ) -Or ( $Name -eq '' ) -Or ( $StorageAccount -eq '' ) -Or ( $Basename -eq '' )){
  Write-Host ""
  Write-Host "==== HELP ===="
  Write-Host "[USAGE]"
  Write-Host "Create-VirtualMachine.ps1 -Name azexample01vm -Size Standard_A1 -StorageAccount azexample01st -Basename azexample01 -Location japaneast"
  Write-Host ""
  Write-Host "[PARAMETERS]"
  Write-Host "Name          : name of virtual machine"
  Write-Host "Size          : size of virtual machine"
  Write-Host "StorageAccount: name of storage account"
  Write-Host "Basename      : basename of resources"
  Write-Host "Location      : location for resources (japaneast, japanwest, eastasia, southeastasia)"
  Write-Host "Help : display help"
  exit 1
}

## variables
if ( $Location -eq '' ) {
  $Location = "japaneast"
}

$locName = $Location.ToLower()
$rgName  = "rg-" + $Basename.ToLower()
$stName  = $StorageAccount.ToLower()

Print-Log "==== START ===="

## credential
$cred = Get-Credential

#variables
$pipName    = "pip-" + $Name.ToLower()
$nicName    = "nic-" + $Name.ToLower()
$dnsName    = $Name.ToLower()
$vmName     = $Name.ToLower()
$vnetName   = "vnet-" + $Basename.ToLower()
$snetName   = "subnet01"

# disk Uri
$storage      = Get-AzureRmStorageAccount `
                -ResourceGroupName $rgName `
                -Name $stName `
                -ErrorAction Stop
if ( !$? ) {
  exit 1
}

$osDiskUri    = $storage.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + "-os.vhd"
$dataDiskUri  = $storage.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + "-data.vhd"
$osDiskName   = $vmName + "-os"
$dataDiskName = $vmName + "-data"

# create NIC
$vnet = Get-AzureRmVirtualNetwork `
        -ResourceGroupName $rgName `
        -Name $vnetName `
        -ErrorAction Stop
if ( !$? ) {
  exit 1
}
$snet = Get-AzureRmVirtualNetworkSubnetConfig `
        -Name $snetName `
        -VirtualNetwork $vnet `
        -ErrorAction Stop
if ( !$? ) {
  exit 1
}
$pip  = New-AzureRmPublicIpAddress `
        -Location $locName `
        -ResourceGroupName $rgName `
        -Name $pipName `
        -DomainNameLabel $dnsName `
        -AllocationMethod Dynamic `
        -ErrorAction Stop
if ( !$? ) {
  exit 1
}
$nic  = New-AzureRmNetworkInterface `
        -Location $locName `
        -ResourceGroupName $rgName `
        -Name $nicName `
        -SubnetId $snet.Id `
        -PublicIpAddressId $pip.Id `
        -ErrorAction Stop
if ( !$? ) {
  exit 1
}

# create a configurable virtual machine object
$vmConfig = New-AzureRmVMConfig `
            -VMName $vmName `
            -VMSize $Size `
            -ErrorAction Stop
if ( !$? ) {
  exit 1
}
$vmConfig = Set-AzureRmVMOperatingSystem `
            -VM $vmConfig `
            -Linux `
            -ComputerName $vmName `
            -Credential $cred `
            -ErrorAction Stop
if ( !$? ) {
  exit 1
}
$vmConfig = Set-AzureRmVMOSDisk `
            -VM $vmConfig `
            -Name $osDiskName `
            -VhdUri $osDiskUri `
            -Caching "ReadWrite" `
            -CreateOption "FromImage" `
            -ErrorAction Stop
if ( !$? ) {
  exit 1
}
$vmConfig = Add-AzureRmVMDataDisk `
            -VM $vmConfig `
            -Name $dataDiskName `
            -VhdUri $dataDiskUri `
            -Caching "ReadWrite" `
            -CreateOption "Empty" `
            -DiskSizeInGB 60 `
            -Lun 0 `
            -ErrorAction Stop
if ( !$? ) {
  exit 1
}
$vmConfig = Add-AzureRmVMNetworkInterface `
            -VM $vmConfig `
            -Id $nic.Id `
            -ErrorAction Stop
$vmImage  = Get-AzureRmVMImagePublisher -Location $locName | `
            ? PublisherName -Like "Canonical" | `
            Get-AzureRmVMImageOffer | `
            ? Offer -eq "UbuntuServer" | `
            Get-AzureRmVMImageSku | `
            ? Skus -like "14.*-LTS" | `
            Get-AzureRmVMImage | `
            Sort-Object Version -Descending | `
            select -First 1
$vmImage | Set-AzureRmVMSourceImage -VM $vmConfig -ErrorAction Stop

New-AzureRmVM `
  -Location $locName `
  -ResourceGroupName $rgName `
  -VM $vmConfig `
  -ErrorAction Stop

##############################################################################
# end
#
Write-Host "==== END ===="
exit 0