$phonefilepath="C:\ExportOU\phone.csv"
$importedusers = Import-Csv -path $phonefilepath

foreach ($user in $importedusers) {
    if($user.telephoneNumber){
    write-host $user.DisplayName $user.telephoneNumber
    set-aduser -Identity $user.samAccountName -MobilePhone $user.telephoneNumber
    }
}