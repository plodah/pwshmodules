function Set-ADUserUPNtoMail {
    param(
        [string[]]$Identity,
        [Parameter()]
        [string]        $Server,
        [Parameter()]
        [PSCredential]  $Credential
    )
    begin{
        $ADSplat = @{  }
        if($Server){ $ADSplat.Server=$Server }
        if($Credential){ $ADSplat.Credential=$Credential }
        $Domain=Get-ADDomain @ADSplat
        $ADUserSplat = $ADSplat
        $ADUserSplat.Properties = "mail"
    }
    process{
        foreach($i in $Identity){
            try{
                $adu = Get-ADUser @ADUserSplat -Identity $i
            }
            catch{
                $adu=$null
                Write-Warning "$i not found"
            }
            if($adu.mail){
                $adu|Set-AdUser -UserPrincipalName $adu.mail
            }
            else{
                Write-Warning "$i probably doesn't have 'mail' property set"
                $adu|set-aduser -UserPrincipalName "$($adu.samaccountname)@$($Domain.DNSRoot)"
            }
            $adu2= Get-ADUser @ADUserSplat -Identity $i
            $OutputObject = New-Object -TypeName PSCustomObject -Property @{
                SamAccountName = $adu.SamAccountName
                OldUPN = $adu.UserPrincipalName
                NewUPN = $adu2.UserPrincipalName
                mail=$adu.mail
            }
            $OutputObject.PsObject.TypeNames.Insert(0,"PlodahPS.UPNtoMail")
            $OutputObject
        }
    }
    end{
    }
}
