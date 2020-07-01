$phonefilepath="C:\ExportOU\phone.csv"
$ou="OU=Sonne,DC=company3,DC=local"
get-aduser -filter * -SearchBase $ou -Properties * | Select-Object DisplayName, samAccountName, telephoneNumber, MobilePhone, mobile  | Export-Csv -Path $phonefilepath -Encoding UTF8 -NoTypeInformation