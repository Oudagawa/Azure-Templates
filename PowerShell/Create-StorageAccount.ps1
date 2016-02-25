##############################################################################
# name:
# Create-StorageAccount.ps1
#
# description:
# create storage account
#
##############################################################################
# variables
#
Param (
  [switch]$Help,
  [string]$Name,
  [ValidateSet("Standard_LRS", "Standard_ZRS", "Standard_GRS", "Standard_RAGRS", "Premium_LRS")][string]$Type,
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
if (( $Help ) -Or ( $Name -eq '' ) -Or ( $Basename -eq '' )){
  Write-Host ""
  Write-Host "==== HELP ===="
  Write-Host "[USAGE]"
  Write-Host "Create-StorageAccount.ps1 -Name azexample01st -Type Standard_LRS -Basename azexample01 -Location japaneast"
  Write-Host ""
  Write-Host "[PARAMETERS]"
  Write-Host "Name    : name of storage account"
  Write-Host "Type    : type of storage account"
  Write-Host "Basename: basename of resources"
  Write-Host "Location: location for resources (japaneast, japanwest, eastasia, southeastasia)"
  Write-Host "Help : display help"
  exit 1
}

## variables
if ( $Location -eq '' ) {
  $Location = "japaneast"
}

$locName = $Location.ToLower()
$rgName  = "rg-" + $Basename.ToLower()
$stName  = $Name.ToLower()

Print-Log "==== START ===="
Write-Host "- Account Name: $stName"
Write-Host "- Account Type: $Type"
Write-Host ""

## storage accounts
New-AzureRmStorageAccount `
  -Location $locName `
  -ResourceGroupName $rgName `
  -Name $stName `
  -Type $Type `
  -ErrorAction Stop

##############################################################################
# end
#
Write-Host "==== END ===="
exit 0