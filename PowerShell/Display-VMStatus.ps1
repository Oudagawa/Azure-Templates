##############################################################################
# name:
# Stop-VirtualMachine.ps1
#
# description:
# stop specified virtual machine
#
##############################################################################
# variables
#
Param (
  [switch]$Help,
  [string]$Name,
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
if (( $Help ) -Or ( $Name -eq '' ) -Or ( $Basename -eq '' )){
  Write-Host ""
  Write-Host "==== HELP ===="
  Write-Host "[USAGE]"
  Write-Host "Stop-VirtualMachine.ps1 -Name azexample01vm -Basename azexample01"
  Write-Host ""
  Write-Host "[PARAMETERS]"
  Write-Host "Name    : name of virtual machine"
  Write-Host "Basename: basename of resources"
  Write-Host "Help    : display help"
  exit 1
}

## variables
$vmName = $Name.ToLower()
$rgName = "rg-" + $Basename.ToLower()

$vm = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName -status -ErrorAction Stop
if ( !$? ) {
  exit 1
}

$vm.Statuses

##############################################################################
# end
#
exit 0