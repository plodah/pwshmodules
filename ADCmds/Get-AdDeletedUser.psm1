
Get-ADObject -Filter {objectSID -eq $ThisUsername} -IncludeDeletedObjects -Properties * @ServerArg
