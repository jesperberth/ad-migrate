# AD-Migrate

Menu driven Active directory Export/Import Tool

Export Active Directory Users, Contacts, Groups and Group Membership to csv files

Create new Users, Contacts and Groups in new Active Directory

Users are created with a new password

Tested on Windows Server 2019

## Manual AD Connect Sync

Import-Module "C:\Program Files\Microsoft Azure Active Directory Connect\AdSyncConfig\AdSyncConfig.psm1"

Start-ADSyncSyncCycle -PolicyType Delta

## Stop Azure AD Connect Sync

Check that Azure AD Connect is configured to use ms-DS-ConsistencyGuid as Source Anchor

Use Azure AD Connect / View current configuration to check

Uninstall Azure AD Connect

Disable Directory Sync In Azure AD

In Powershell

__Note:__ It can take up to 72hours to complete, keep checking with (Get-MSOLCompanyInformation).DirectorySynchronizationEnabled

```powershell
Install-Module -Name MSonline

$msolcred = get-credential

connect-msolservice -credential $msolcred

Set-MsolDirSyncEnabled -EnableDirSync $false

(Get-MSOLCompanyInformation).DirectorySynchronizationEnabled

(Get-MSOLCompanyInformation).DirectorySynchronizationStatus

```

Wait for Disabled

## Export Users, Groups and Contacts from Source AD