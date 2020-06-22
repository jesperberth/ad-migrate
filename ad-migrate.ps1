# Menu driven AD Migration Tool
#
# Author: Jesper Berth, Arrow ECS, jesper.berth@arrow.com - 22/06-2020
# Version 0.0.1
function Show-Menu
{
    param (
        [string]$Title = "AD Migration"
    )
    Clear-Host
    Write-Host "======== $Title ========`n"
    Write-Host "1: Install Standard Software"
    Write-Host "2: Install Adobe Creative Suite"
    Write-Host "3: Install Programming Suite"
    Write-Host "4: Install Video Suite"
    Write-Host "5: Run Support Tool"
    Write-Host "6: Setup Netshare and Print"
    Write-Host "==============================="
    Write-Host "99: Run Driver Tool"
    Write-Host "==============================="
    Write-Host "Q: Press 'Q' to quit."
    Write-Host "==============================="
}


function SetSourceOU{


}

do
 {
     Show-Menu
     $selection = Read-Host "Please make a selection"
     switch ($selection)
     {
         '1' {
             Clear-Host            
             SetSourceOU
         } '2' {
             Clear-Host
             GetSourceToCSV
         } '3' {
             Clear-Host
             InstallCode
         } '4' {
             Clear-Host
             InstallVideo
         } '5' {
             Clear-Host
             RunSupport
         } '6' {
             Clear-Host
             RunNetPrint
         } '99' {
             Clear-Host
             drivertool
         }
     }
     pause
 }
 until ($selection -eq 'q')