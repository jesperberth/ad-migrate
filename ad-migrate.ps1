# Menu driven AD Migration Tool
# Exports Groups Contacts, Users and Mappings between Groups and Users
# Author: Jesper Berth, Arrow ECS, jesper.berth@arrow.com - 22/06-2020
# Version 0.7.0
$path = "C:\ExportOU\"
$groupfile = "group.csv"
$groupmembersfile = "groupmembers.csv"
$userfile = "users.csv"
$contactfile = "contact.csv"
$usercreatefile = "user_created.csv"
function Show-Menu
{
    param (
        [string]$Title = "AD Migration"
    )
    Clear-Host
    Write-Host "======== $Title ========`n"
    Write-Host "1: Set Source/Destination OU for Export and Import"
    Write-Host "2: Export Groups, Contacts and Users to CSV"
    Write-Host "3: Import Groups, Contacts and Users"
    Write-Host "`nQ: Press 'Q' to quit."
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
    $exportcontactpath = $path + $contactfile
    $exportgroupmemberspath = $path + $groupmembersfile
    write-host -foregroundcolor green "#####################################################################`n"
    write-host -foregroundcolor green "# Export all Groups and users to CSV file from: " $ou "`n"
    write-host -foregroundcolor green "#####################################################################`n"
    get-adgroup -filter * -SearchBase $ou -Properties * | Select-Object DistinguishedName, Description, Name, GroupCategory, GroupScope, Mail, objectGUID | Export-Csv -Path $exportgrouppath -Encoding UTF8 -NoTypeInformation
    # Get user details
    get-aduser -filter * -SearchBase $ou -Properties * | Select-Object DisplayName, City, CN, Company, Country, countryCode, Department, Description, Division, EmailAddress, EmployeeID, EmployeeNumber, Fax, GivenName, HomeDirectory, HomedirRequired, HomeDrive, HomePage, HomePhone, Initials, Manager, MobilePhone, Name, Office, OfficePhone, Organization, OtherName, POBox, PostalCode, ProfilePath, SamAccountName, ScriptPath, sn, State, StreetAddress, Surname, Title, UserPrincipalName, objectGUID | Export-Csv -Path $exportuserpath -Encoding UTF8 -NoTypeInformation

    Get-ADObject -Filter 'objectClass -eq "contact"' -Properties * | Select-Object Name, DisplayName, c, co, company, countryCode, department, Description, facsimileTelephoneNumber, givenName, homePhone, initials, ipPhone, l, mail, mobile, pager, physicalDeliveryOfficeName, postalCode, sn, st, streetAddress, telephoneNumber, title, wWWHomePage, objectGUID | Export-Csv -Path $exportcontactpath -Encoding UTF8 -NoTypeInformation    

    $groups = (Import-Csv -Path $exportgrouppath).Name
    
    $groupmemberheader = """Name"", ""SamAccountName"""

    Add-Content -Encoding utf8 -Path $exportgroupmemberspath -Value $groupmemberheader

    foreach($group in $groups){
        write-host -ForegroundColor Cyan $group
        $groupmember = get-adgroupmember -Identity $group | Where-Object {$_.objectClass -ne  "computer"} | Select-Object SamAccountName
        write-host -ForegroundColor Magenta $groupmember.SamAccountName

        
        foreach($member in $groupmember){
            $membername = $member.SamAccountName
            $groupmemberline = """$group"", ""$membername"""
            Add-Content -Encoding utf8 -Path $exportgroupmemberspath -Value $groupmemberline
        }
    }
    write-host -foregroundcolor green "###############################################`n"
    write-host -foregroundcolor green "# Export of Users, Contacts and Groups Done ! #`n"
    write-host -foregroundcolor green "###############################################`n"
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
    $importuserfile = $path + "users.csv"
    $importgroupmembersfile = $path + "groupmembers.csv"
    $importcontactsfile = $path + "contact.csv"
    $createdusersfile = $path + $usercreatefile
    
    $fileNames = Get-ChildItem -Path $path
    foreach ($file in $fileNames) {
        write-host "file: $file`n"
    }

    # Group Import
    # 

    $importgroupou = "OU=Import_Groups," + $ou
    write-host "`nImport following AD Groups into $importgroupou`n"

    $importedgroups = Import-Csv -path $importgroupsfile

    foreach ($group in $importedgroups) {
        $groupname = $group.Name
        $groupalias = get-adgroup -filter {Name -eq $groupname} -ErrorAction SilentlyContinue
        if(!$groupalias){
            write-host "Create : " $group.Name
            New-adgroup -Path $importgroupou -Name $group.Name -GroupScope $group.GroupScope -GroupCategory $group.GroupCategory -Description $group.Description
                if($group.Mail){
                    write-host -foregroundcolor yellow "add mailaddress"
                    Set-ADGroup $group.Name -Replace @{mail=$group.Mail}
                }
                write-host "Set mS-DS-ConsistencyGuid"
                $objectGuid = [GUID] $group.objectGUID
                write-host $objectGuid
                set-adgroup -identity $group.Name -Replace @{'mS-DS-ConsistencyGuid'=$objectGuid}
            }
            else{
                write-host -foregroundcolor red "Group exist, skip creation: " $group.Name
            }
        
    }

    # user import
    #
    $passwordlength = 16
    $importuserou = "OU=Import_Users," + $ou
    write-host "`nImport following AD Users into $importuserou`n"

    $importedusers = Import-Csv -path $importuserfile

    $usercreatedheader = """DisplayName"", ""EmailAddress"", ""Password"""

    Add-Content  -Encoding utf8 -Path $createdusersfile -Value $usercreatedheader

    foreach ($user in $importedusers) {
        $password = GetPasswordRandom $passwordlength
        #write-host $user.DisplayName " " $password
        $securepassword = (ConvertTo-SecureString -AsPlainText $password -Force)
        $userSAM = $user.SamAccountName
       
        $alias = Get-ADUser -filter {SamAccountName -eq $userSAM} -ErrorAction SilentlyContinue
        if(!$alias){
            #CN countryCode HomedirRequired Manager sn
            New-aduser -Path $importuserou -Enabled $true -DisplayName $user.DisplayName -City $user.City -Company $user.Company -Country $user.Country -Department $user.Department -Description $user.Description -Division $user.Division -EmailAddress $user.EmailAddress -EmployeeID $user.EmployeeID -EmployeeNumber $user.EmployeeNumber -Fax $user.Fax -GivenName $user.GivenName -HomeDirectory $user.HomeDirectory  -HomeDrive $user.HomeDrive -HomePage $user.HomePage -HomePhone $user.HomePhone -Initials $user.Initials -MobilePhone $user.MobilePhone -Name $user.Name -Office $user.Office -OfficePhone $user.OfficePhone -Organization $user.Organization -OtherName $user.OtherName -POBox $user.POBox -PostalCode $user.PostalCode -ProfilePath $user.ProfilePath -SamAccountName $user.SamAccountName -ScriptPath $user.ScriptPath -State $user.State -StreetAddress $user.StreetAddress -Surname $user.Surname -Title $user.Title -UserPrincipalName $user.UserPrincipalName -AccountPassword $securepassword
            write-host "Create user: " $user.DisplayName
           $userDisplayName = $user.DisplayName
           $userEmailAddress = $user.EmailAddress
            $createduserline = """$userDisplayName"", ""$userEmailAddress"", ""$password"""
            Add-Content  -Encoding utf8 -Path $createdusersfile -Value $createduserline
            write-host "Set mS-DS-ConsistencyGuid"
            $objectGuid = [GUID] $user.objectGUID
            write-host $objectGuid
            set-aduser -identity $user.SamAccountName -Replace @{'mS-DS-ConsistencyGuid'=$objectGuid}
            }
            else{
                write-host -ForegroundColor red "User exist, skip creation: " $user.SamAccountName
            }

    }

    # Contact Import
    # 

    $importcontactou = "OU=Import_Contacts," + $ou
    write-host "`nImport following AD Contacts into $importcontactou`n"

    $importedcontacts = Import-Csv -path $importcontactsfile

    foreach ($contact in $importedcontacts) {
        $contactname = $contact.Name
        $contactalias = Get-ADObject -Filter {objectClass -eq "contact" -and Name -eq $contactname} -ErrorAction SilentlyContinue
        if(!$contactalias){
            write-host "Create : " $contact.Name
            New-ADObject -type contact -path $importcontactou -Name $contact.Name
            $contactArray = @('DisplayName', 'c', 'co', 'company', 'countryCode', 'department', 'Description', 'facsimileTelephoneNumber', 'givenName', 'homePhone', 'initials', 'ipPhone', 'l', 'mail', 'mobile', 'pager', 'physicalDeliveryOfficeName', 'postalCode', 'sn', 'st', 'streetAddress', 'telephoneNumber', 'title', 'wWWHomePage')
            foreach($ca in $contactArray){
                if($contact.$ca){
                    $addObject = @{$ca=$contact.$ca}
                    write-host $ca ": " $contact.$ca
                    Get-ADObject -Filter {objectClass -eq "contact" -and Name -eq $contactname} | set-adobject -Replace $addObject
                }
            }
            write-host "Set mS-DS-ConsistencyGuid"
            $objectGuid = [GUID] $contact.objectGUID
            write-host $objectGuid
            Get-ADObject -Filter {objectClass -eq "contact" -and Name -eq $contactname} | set-adobject -Replace @{'mS-DS-ConsistencyGuid'=$objectGuid}                      
            
            }
            else{
                write-host -foregroundcolor red "Contact exist, skip creation: " $contact.Name
            }
        
    }

    # user -> group import
    #

    write-host "`nAssign Groups to users`n"

    $importedgroupmembers = Import-Csv -path $importgroupmembersfile

    foreach ($groupmember in $importedgroupmembers) {
        write-host "For group: "$groupmember.Name " - Add member: " $groupmember.SamAccountName
        Add-ADGroupMember -Identity $groupmember.Name -Members $groupmember.SamAccountName
    }

}

function GetPasswordRandom($count) {
    $Password = ( -join ((0x30..0x39) + ( 0x41..0x5A) + ( 0x61..0x7A) | Get-Random -Count $count  | ForEach-Object {[char]$_}) )
    #$numb = ( -join ((0x30..0x39)  | Get-Random -Count $count  | ForEach-Object {[char]$_}) )
    #$pre = "SomeThingSecure"
    #$password = $pre + $numb
    return $password
    
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