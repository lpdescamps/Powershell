$today = get-date -Format "yyyyMMdd_HHmmss"
$src = "C:\shared\ps1\import_20200514.csv"
$dst = "C:\shared\ps1\export_$($today).csv"


$emails = Import-Csv $src

ForEach ($email in $emails)
{

    $mailaddress = $email.mailaddress

    Get-ADUser -Filter { mail -like $mailaddress } -properties TelephoneNumber, mail, DisplayName |
            Select-Object Name, GivenName, Surname, DisplayName, @{ Name = "TelephoneNumber"; Expression = { "\{0}" -f $_.TelephoneNumber.Replace(" ","") } }, mail |
            Export-Csv $dst -NoTypeInformation -Append

}
Start-Process $dst