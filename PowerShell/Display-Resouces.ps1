##############################################################################
# name:
# Display-Resources.ps1
#
# description:
# login and selct subscription
#
##############################################################################
# variables
#
Param (
  [switch]$Help,
  [string]$Basename
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

if ( $Help ) {
  Write-Host ""
  Write-Host "==== HELP ===="
  Write-Host "[USAGE]"
  Write-Host "Display-Resources.ps1 -Name alfexample01"
  Write-Host ""
  Write-Host "[PARAMETERS]"
  Write-Host "Basename: basename of resources"
  Write-Host "Help    : display help"
  exit 1
}

$rgName = "rg-" + $Basename.ToLower()

## display resouce
Get-AzureRmResource | ? { $_.ResourceGroupName -eq $rgName } | Select Name,ResourceType

##############################################################################
# end
#
exit 0