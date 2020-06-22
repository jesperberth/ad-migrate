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
    Write-Host "1: Set Source OU for Export"
    Write-Host "2: Export Groups and Users to CSV"
    Write-Host "3: "
    Write-Host "Q: Press 'Q' to quit."
    Write-Host "==============================="
}


function SetSourceOU{
    write-host "Type Souce OU for Export`n Example: OU=ExportOU,DC=arrowdemo,DC=local "
    $ou = Read-Host "Type Source OU"
    return $ou

}

function ExportSourceToCSV($ou){
    $exportpath = "C:\ExportOU\"
    $exportgroupfile = "group.csv"
   # $exportgroupmembersfile = "groupmembers.csv"
    $exportuserfile = "users.csv"
    if($null -eq $ou){
        write-host -ForegroundColor red "You Need to set the Export OU, press any key to continue"
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        break
    }

    $exportpathmsg = "Do you want to change Default Export path y/n"
	do {
		write-host -foregroundcolor yellow "Default Export path C:\ExportOU\`n"
		$response = Read-Host -Prompt $exportpathmsg
		if ($response -eq 'y') {
            $exportpath = Read-Host -Prompt "Set Export path"
            write-host -foregroundcolor yellow "New export path: " $exportpath
		$response = "n"
 		}
	} 	until ($response -eq 'n')
    New-Item -ItemType "directory" -Path $exportpath -Force
    $exportgrouppath = $exportpath + $exportgroupfile
    $exportuserpath = $exportpath + $exportuserfile
    write-host -foregroundcolor green "`n#####################################################################`n"
    write-host -foregroundcolor green "Export all Groups and users to CSV file from: " $ou "`n"
    write-host -foregroundcolor green "#####################################################################`n"
    get-adgroup -filter * -SearchBase $ou -Properties * | Select-Object DistinguishedName, Description, Name, GroupCategory, GroupScope | Export-Csv -Path $exportgrouppath -Encoding UTF8
    # Get user details
    get-aduser -filter * -SearchBase $ou -Properties * | Select-Object DisplayName, City, CN, Company, Country, countryCode, Department, Description, Division, EmailAddress, EmployeeID, EmployeeNumber, Fax, GivenName, HomeDirectory, HomedirRequired, HomeDrive, HomePage, HomePhone, Initials, Manager, MobilePhone, Name, Office, OfficePhone, Organization, OtherName, POBox, PostalCode, ProfilePath, SamAccountName, ScriptPath, sn, State, StreetAddress, Surname, Title, UserPrincipalName | Export-Csv -Path $exportuserpath -Encoding UTF8
}

do
 {
     Show-Menu
     $selection = Read-Host "Please make a selection"
     switch ($selection)
     {
         '1' {
             Clear-Host            
             $ou = SetSourceOU
         } '2' {
             Clear-Host
             ExportSourceToCSV $ou
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