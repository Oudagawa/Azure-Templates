##############################################################################
# name:
#
# description:
#
##############################################################################
# variables
#
Param (
  [switch]$Help,
  [string]$Basename,
  [ValidateSet("japaneast", "japanwest", "eastasia", "southeastasia")][string]$Location
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

function Test-Dir( [string] $dir ) {
  if ( !( Test-Path $dir ) ) {
    New-Item $dir -ItemType Directory -Force
  }
}

##############################################################################
# start
# {
if ( ( $Help ) -Or ( $Basename -eq '' ) ){
  Write-Host ""
  Write-Host "==== HELP ===="
  Write-Host "[USAGE]"
  Write-Host "New-CMS.ps1 -Basename azexample -Location japaneast"
  Write-Host ""
  Write-Host "[PARAMETERS]"
  Write-Host "Basename: basename of resources"
  Write-Host "Location: location for resources (japaneast, japanwest, eastasia, southeastasia)"
  Write-Host "Help : display help"
  exit 1
} else {
  if ( $Location -eq '' ) {
    $Location = "japaneast"
  }
  Print-Log "==== START ===="

  $locName = $Location.ToLower()
}

##############################################################################
# login
#
Print-Log "## login to Azure"

#$azaccount = Login-AzureRmAccount -ErrorAction Stop

##############################################################################
# select subscription
#
Print-Log "## select subscription"

$subscription = Get-AzureRmSubscription | Out-GridView -OutputMode Single
$subId = $subscription.SubscriptionId

Select-AzureRmSubscription -SubscriptionId $subId -ErrorAction Stop

##############################################################################
# resource group
#
Print-Log "## rosource group"

$rgName = "rg-" + $Basename.ToLower()

New-AzureRmResourceGroup -Name $rgName -Location $locName -ErrorAction Stop

##############################################################################
# storage accounts
#
Print-Log "## storage account"

$stName = $Basename.ToLower() + "st"
$stType = "Standard_LRS"

New-AzureRmStorageAccount -Location $locName -ResourceGroupName $rgName `
  -Name $stName -Type $stType -ErrorAction Stop


##############################################################################
# availability set
#
Print-Log  "## availability set"

$asName = "as-" + $Basename.ToLower()

$avSet = New-AzureRmAvailabilitySet -Location $locName -ResourceGroupName $rgName `
         -Name $asName -ErrorAction Stop
if ( !$? ) {
  exit 1
}

##############################################################################
# network security group
#
Print-Log  "## network security group"

$nsgName = "nsg-" + $Basename.ToLower()

$rule01 = New-AzureRmNetworkSecurityRuleConfig -Name ssh -Description "Allow SSH" `
          -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
          -SourceAddressPrefix * -SourcePortRange * `
          -DestinationAddressPrefix * -DestinationPortRange 22 -ErrorAction Stop
$rule02 = New-AzureRmNetworkSecurityRuleConfig -Name http -Description "Allow HTTP" `
          -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 `
          -SourceAddressPrefix * -SourcePortRange * `
          -DestinationAddressPrefix * -DestinationPortRange 80 -ErrorAction Stop
$rule03 = New-AzureRmNetworkSecurityRuleConfig -Name https -Description "Allow HTTPS" `
          -Access Allow -Protocol Tcp -Direction Inbound -Priority 120 `
          -SourceAddressPrefix * -SourcePortRange * `
          -DestinationAddressPrefix * -DestinationPortRange 443 -ErrorAction Stop

$nsg = New-AzureRmNetworkSecurityGroup -Location $locName -ResourceGroupName $rgName `
       -Name $nsgName -SecurityRules $rule01,$rule02,$rule03 -ErrorAction Stop

##############################################################################
# virtual network
#
Print-Log "## virtual network"

$vnetName   = "vnet-" + $Basename.ToLower()
$snetName   = "cms"
$vnetPrefix = "10.0.0.0/16"
$snetPrefix = "10.0.0.0/24"

$vnet = New-AzureRmVirtualNetwork -Location $locName -ResourceGroupName $rgName `
        -Name $vnetName -AddressPrefix $vnetPrefix -ErrorAction Stop

Add-AzureRmVirtualNetworkSubnetConfig -Name $snetName -VirtualNetwork $vnet `
  -AddressPrefix $snetPrefix -NetworkSecurityGroup $nsg -ErrorAction Stop

Set-AzureRmVirtualNetwork -VirtualNetwork $vnet -ErrorAction Stop

##############################################################################
# load balancer
#
Print-Log "## load balancer"

$lbName     = "lb-" + $basename.ToLower()
$pipName_lb = "pip-" + $Basename.ToLower()
$dnsName_lb = $Basename.ToLower()
$feConfName = "LoadBalancerFrontEnd"
$beConfName = "BackendPool01"
$probeName  = "lbProbe"

$pip_lb      = New-AzureRmPublicIpAddress -Location $locName -ResourceGroupName $rgName `
               -Name $pipName_lb -AllocationMethod "Dynamic" `
               -DomainNameLabel $dnsName_lb -ErrorAction Stop
$feIpConfig  = New-AzureRmLoadBalancerFrontendIpConfig -Name $feConfName `
               -PublicIpAddress $pip_lb -ErrorAction Stop
$beAdrsPool  = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name $beConfName `
               -ErrorAction Stop
$healthProbe = New-AzureRmLoadBalancerProbeConfig -Name $probeName `
               -Protocol Tcp -Port 80 -IntervalInSeconds 5 -ProbeCount 2 `
               -ErrorAction Stop

$lbRule01 = New-AzureRmLoadBalancerRuleConfig -Name "LBRule-SSH" `
            -FrontendIpConfiguration $feIpConfig -BackendAddressPool $beAdrsPool `
            -Protocol Tcp -FrontendPort 30022 -BackendPort 22 `
            -Probe $healthProbe -LoadDistribution Default -IdleTimeoutInMinutes 5 `
            -ErrorAction Stop
$lbRule02 = New-AzureRmLoadBalancerRuleConfig -Name "LBRule-HTTP" `
            -FrontendIpConfiguration $feIpConfig -BackendAddressPool $beAdrsPool `
            -Protocol Tcp -FrontendPort 80 -BackendPort 80 `
            -Probe $healthProbe -LoadDistribution Default -IdleTimeoutInMinutes 5 `
            -ErrorAction Stop
$lbRule03 = New-AzureRmLoadBalancerRuleConfig -Name "LBRule-HTTPS" `
            -FrontendIpConfiguration $feIpConfig -BackendAddressPool $beAdrsPool `
            -Protocol Tcp -FrontendPort 443 -BackendPort 443 `
            -Probe $healthProbe -LoadDistribution Default -IdleTimeoutInMinutes 5 `
            -ErrorAction Stop

$lb = New-AzureRmLoadBalancer -Location $locName -ResourceGroupName $rgName `
      -Name $lbName -FrontendIpConfiguration $feIpConfig -BackendAddressPool $beAdrsPool `
      -LoadBalancingRule $lbRule01,$lbRule02,$lbRule03 -Probe $healthProbe `
      -ErrorAction Stop

##############################################################################
# virtual machine
#
# credential
$cred = Get-Credential

$list = "00","01"
Foreach ( $val in $list ) {
  #variables
  $pipName    = "pip-" + $Basename.ToLower() + "-" + $val
  $nicName    = "nic-" + $Basename.ToLower() + "-" + $val
  $dnsName    = $Basename.ToLower() + "-" + $val
  $vmName     = $Basename.ToLower() + "-" + $val
  $vmSize     = "Standard_A1"
  $vnetName   = "vnet-" + $Basename.ToLower()
  $snetName   = "cms"

  # disk Uri
  $storage      = Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $stName `
                  -ErrorAction Stop
  $osDiskUri    = $storage.PrimaryEndpoints.Blob.ToString() + "vhds/" + "os" + $val + ".vhd"
  $dataDiskUri  = $storage.PrimaryEndpoints.Blob.ToString() + "vhds/" + "data" + $val + ".vhd"
  $osDiskName   = $Basename.ToLower() + "os" + $val
  $dataDiskName = $Basename.ToLower() + "data" + $val

  # create NIC
  $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName -ErrorAction Stop
  $snet = Get-AzureRmVirtualNetworkSubnetConfig -Name $snetName -VirtualNetwork $vnet -ErrorAction Stop

  $pip = New-AzureRmPublicIpAddress -Location $locName -ResourceGroupName $rgName `
         -Name $pipName -DomainNameLabel $dnsName -AllocationMethod Dynamic `
         -ErrorAction Stop
  $nic = New-AzureRmNetworkInterface -Location $locName -ResourceGroupName $rgName `
         -Name $nicName -SubnetId $snet.Id -PublicIpAddressId $pip.Id `
         -LoadBalancerBackendAddressPoolId $lb.BackendAddressPools[0].Id -ErrorAction Stop

  # create a configurable virtual machine object
  $vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize `
              -AvailabilitySetID $avSet.Id -ErrorAction Stop
  $vmConfig = Set-AzureRmVMOperatingSystem -VM $vmConfig -Linux `
              -ComputerName $vmName -Credential $cred -ErrorAction Stop
  $vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -Name $osDiskName -VhdUri $osDiskUri `
              -Caching "ReadWrite" -CreateOption "FromImage" -ErrorAction Stop
  $vmConfig = Add-AzureRmVMDataDisk -VM $vmConfig -Name $dataDiskName -VhdUri $dataDiskUri `
              -Caching "ReadWrite" -CreateOption "Empty" -DiskSizeInGB 60 -Lun 0 `
              -ErrorAction Stop
  $vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic.Id -ErrorAction Stop
  $vmImage  = Get-AzureRmVMImagePublisher -Location $locName | ? PublisherName -Like "Canonical" | `
              Get-AzureRmVMImageOffer | ? Offer -eq "UbuntuServer" | `
              Get-AzureRmVMImageSku | ? Skus -like "14.*-LTS" | `
              Get-AzureRmVMImage | Sort-Object Version -Descending | select -First 1
  $vmImage | Set-AzureRmVMSourceImage -VM $vmConfig -ErrorAction Stop

  New-AzureRmVM -Location $locName -ResourceGroupName $rgName -VM $vmConfig -ErrorAction Stop
}

##############################################################################
# end
#
Write-Host "==== END ===="
exit 0