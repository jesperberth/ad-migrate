# Menu driven AD Migration Tool
# Exports Groups, Users and Mappings between Groups and Users
# Author: Jesper Berth, Arrow ECS, jesper.berth@arrow.com - 22/06-2020
# Version 0.0.1
$path = "C:\ExportOU\"
$groupfile = "group.csv"
$groupmembersfile = "groupmembers.csv"
$userfile = "users.csv"
function Show-Menu
{
    param (
        [string]$Title = "AD Migration"
    )
    Clear-Host
    Write-Host "======== $Title ========`n"
    Write-Host "1: Set Source/Destination OU for Export and Import"
    Write-Host "2: Export Groups and Users to CSV"
    Write-Host "3: Import Groups and Users"
    Write-Host "Q: Press 'Q' to quit."
    Write-Host "==============================="
}


function SetOU{
    write-host "Type OU for Export or Import`n Example: OU=ExportOU,DC=arrowdemo,DC=local "
    $ou = Read-Host "Type OU"
    return $ou

}

function ExportSourceToCSV($ou){
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
            $path = Read-Host -Prompt "Set Export path"
            write-host -foregroundcolor yellow "New export path: " $path
		$response = "n"
 		}
	} 	until ($response -eq 'n')
    New-Item -ItemType "directory" -Path $path -Force
    $exportgrouppath = $path + $groupfile
    $exportuserpath = $path + $userfile
    $exportgroupmemberspath = $path + $groupmembersfile
    write-host -foregroundcolor green "#####################################################################`n"
    write-host -foregroundcolor green "# Export all Groups and users to CSV file from: " $ou "`n"
    write-host -foregroundcolor green "#####################################################################`n"
    get-adgroup -filter * -SearchBase $ou -Properties * | Select-Object DistinguishedName, Description, Name, GroupCategory, GroupScope | Export-Csv -Path $exportgrouppath -Encoding UTF8 -NoTypeInformation
    # Get user details
    get-aduser -filter * -SearchBase $ou -Properties * | Select-Object DisplayName, City, CN, Company, Country, countryCode, Department, Description, Division, EmailAddress, EmployeeID, EmployeeNumber, Fax, GivenName, HomeDirectory, HomedirRequired, HomeDrive, HomePage, HomePhone, Initials, Manager, MobilePhone, Name, Office, OfficePhone, Organization, OtherName, POBox, PostalCode, ProfilePath, SamAccountName, ScriptPath, sn, State, StreetAddress, Surname, Title, UserPrincipalName | Export-Csv -Path $exportuserpath -Encoding UTF8 -NoTypeInformation

    $groups = (Import-Csv -Path $exportgrouppath).Name
    
    $groupmemberheader = """Name"", ""SamAccountName"""

    Add-Content -Path $exportgroupmemberspath -Value $groupmemberheader

    foreach($group in $groups){
        write-host -ForegroundColor Cyan $group
        $groupmember = get-adgroupmember -Identity $group | Select-Object SamAccountName
        write-host -ForegroundColor Magenta $groupmember.SamAccountName

        
        foreach($member in $groupmember){
            $membername = $member.SamAccountName
            $groupmemberline = """$group"", ""$membername"""
            Add-Content -Path $exportgroupmemberspath -Value $groupmemberline
        }
    }
    write-host -foregroundcolor green "#####################################`n"
    write-host -foregroundcolor green "# Export of Users and Groups Done ! #`n"
    write-host -foregroundcolor green "#####################################`n"
}

function ImportGroupsUsers {

    $exportpathmsg = "Do you want to change Default Import path y/n"
	do {
		write-host -foregroundcolor yellow "Default Import path C:\ExportOU\`n"
		$response = Read-Host -Prompt $exportpathmsg
		if ($response -eq 'y') {
            $path = Read-Host -Prompt "Set Import path"
            write-host -foregroundcolor yellow "New Import path: " $path
		$response = "n"
 		}
    } 	until ($response -eq 'n')
    $importgroupsfile = $path + "group.csv"
    $fileNames = Get-ChildItem -Path $path
    foreach ($file in $fileNames) {
        write-host "file: $file`n"
    }

    $importgroupou = "OU=Import_Groups," + $ou
    write-host "Import following AD Groups into $importgroupou`n"

    $importedgroups = Import-Csv -path $importgroupsfile

    foreach ($group in $importedgroups) {
        write-host $group.Name
        New-adgroup -Path $importgroupou -Name $group.Name -GroupScope $group.GroupScope -GroupCategory $group.GroupCategory -Description $group.Description
    }
}

do
 {
     Show-Menu
     $selection = Read-Host "Please make a selection"
     switch ($selection)
     {
         '1' {
             Clear-Host            
             $ou = SetOU
         } '2' {
             Clear-Host
             ExportSourceToCSV $ou
         } '3' {
             Clear-Host
             ImportGroupsUsers
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