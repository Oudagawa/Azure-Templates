##############################################################################
# name:
# Select-Subscription.ps1
#
# description:
# login and selct subscription
#
##############################################################################
# variables
#
Param (
  [switch]$Help
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
  Write-Host "Login to Azure service, select subscrption, and display resource groups."
  Write-Host ""
  Write-Host "[USAGE]"
  Write-Host "Select-Subscriptin.ps1"
  Write-Host ""
  Write-Host "[PARAMETERS]"
  Write-Host "Help: display help"
  exit 1
}

## login
$azaccount = Login-AzureRmAccount -ErrorAction Stop

## select subscription
$subscription = Get-AzureRmSubscription | Out-GridView -OutputMode Single
$subId        = $subscription.SubscriptionId
$status       = Select-AzureRmSubscription -SubscriptionId $subId -ErrorAction Stop
if ( !$? ) {
  exit 1
}

## subscription
Write-Host ""
Write-Host "Subscription Name:" $subscription.SubscriptionName
Write-Host "Subscription Id  :" $subscription.SubscriptionId

## display resouce group
Get-AzureRmResourceGroup | Select ResourceGroupName,Location

##############################################################################
# end
#
exit 0