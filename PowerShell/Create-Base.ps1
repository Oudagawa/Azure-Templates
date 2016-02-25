##############################################################################
# name:
# Create-Base.ps1
#
# description:
# create resource group and virtual network
#
##############################################################################
# parameters
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

##############################################################################
# start
# 
if ( ( $Help ) -Or ( $Basename -eq '' ) ){
  Write-Host ""
  Write-Host "==== HELP ===="
  Write-Host "[USAGE]"
  Write-Host "Create-Base.ps1 -Basename azexample01 -Location japaneast"
  Write-Host ""
  Write-Host "[PARAMETERS]"
  Write-Host "Basename: basename of resources"
  Write-Host "Location: location for resources (japaneast, japanwest, eastasia, southeastasia)"
  Write-Host "Help : display help"
  exit 1
}

## variables
if ( $Location -eq '' ) {
  $Location = "japaneast"
}

$locName    = $Location.ToLower()
$rgName     = "rg-" + $Basename.ToLower()
$vnetName   = "vnet-" + $Basename.ToLower()
$snetName   = "subnet01"
$vnetPrefix = "10.0.0.0/16"
$snetPrefix = "10.0.0.0/24"
$nsgName    = "nsg-" + $Basename.ToLower()

Print-Log "==== START ===="
Write-Host "- Resource Group Name : $rgName "
Write-Host "- Virtual Network Name: $vnetName"
Write-Host ""

## login
$azaccount = Login-AzureRmAccount -ErrorAction Stop

## select subscription
$subscription = Get-AzureRmSubscription | Out-GridView -OutputMode Single
$subId = $subscription.SubscriptionId
Select-AzureRmSubscription -SubscriptionId $subId -ErrorAction Stop

## resource group
New-AzureRmResourceGroup `
  -Name $rgName `
  -Location $locName `
  -ErrorAction Stop
if ( !$? ) {
  exit 1
}

## network security group
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

$nsg = New-AzureRmNetworkSecurityGroup `
       -Location $locName `
       -ResourceGroupName $rgName `
       -Name $nsgName `
       -SecurityRules $rule01,$rule02,$rule03 `
       -ErrorAction Stop
if ( !$? ) {
  exit 1
}

## virtual network
$vnet = New-AzureRmVirtualNetwork `
        -Location $locName `
        -ResourceGroupName $rgName `
        -Name $vnetName `
        -AddressPrefix $vnetPrefix `
        -ErrorAction Stop
if ( !$? ) {
  exit 1
}

Add-AzureRmVirtualNetworkSubnetConfig `
  -Name $snetName `
  -VirtualNetwork $vnet `
  -AddressPrefix $snetPrefix `
  -NetworkSecurityGroup $nsg `
  -ErrorAction Stop
if ( !$? ) {
  exit 1
}

Set-AzureRmVirtualNetwork `
  -VirtualNetwork $vnet `
  -ErrorAction Stop

##############################################################################
# end
#
Write-Host "==== END ===="
exit 0