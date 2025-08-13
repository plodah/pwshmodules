function Get-ADParentObject {
    [cmdletbinding(DefaultParameterSetName='Identity')]
    param(
        
        [Parameter(Position=0)]
        [string[]]$Identity,
            
        [parameter(ValueFromPipeline=$True)]
        [Microsoft.ActiveDirectory.Management.ADObject[]]$ADObject,
        [parameter()]
        [string]$Server,
        [Parameter()]
        [pscredential]  $Credential
        
    )
    begin{
        $AdSplat = @{
            Properties = "samaccountname"
        }
        if($Server){
            $AdSplat.Server=$Server
        }
        if($Credential){
            $AdSplat.Credential=$Credential
        }
    }
    process{
        $PassObj = & {
            foreach($i in $Identity){
                try{
                    $Obj = Get-ADObject -Identity $i @AdSplat
                }
                catch{
                    $Obj = Get-ADObject -Filter "samaccountname -eq `"$i`"" @AdSplat | Sort-Object -Property samaccountname
                    if( ($Obj|Measure-Object).Count -gt 1){
                        $Obj = $Obj | Sort-Object -Property Samaccountname | Select-Object -First 1
                        Write-Warning "Multiple Results - using first $($Obj.Distinguishedname)"
                    }
                }
                $Obj
            }
            if($ADObject){$ADObject}
        }
        foreach($p in $PassObj){
            if($p.ObjectClass -eq "domainDNS"){
                Write-Warning "Don't be silly - you're asking for the parent object of the root!"
                $p
            }
            else{
                Get-ADObject -Identity "$(([ADSI](([ADSI]"LDAP://$($p.distinguishedName)").Parent)).DistinguishedName)" @AdSplat
            }
        }
    }
    end{
    }
}
