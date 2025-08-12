function Get-CipherSuite {
    [CmdletBinding()] 
    param(
        [Parameter( )]
        [string[]] $Name = "*",
        [Parameter( )]
        [ValidateSet("Recommended","Secure","Weak","Insecure")]
        [string[]] $Security,
        [Parameter( )]
        [switch] $RetrieveCiphers
    )
    begin{
        $OutputType = "PlodahPS.CipherSuite"
        ##Get into from "ciphersuite.info"
        $InfoUrl = "https://ciphersuite.info/api/cs"
        #$CipherJson = "$PSScriptRoot\Source\CipherList.json"
        $CipherCsv = "$PSScriptRoot\Source\CipherList.csv"
        if(Test-Path $CipherCsv){
            Write-Verbose -Message "Local cipher info present."
            try{
                $CipherList = Import-Csv -Path $CipherCsv
            }
            catch{
                
            }
        }
        if($RetrieveCiphers -or (-not $CipherList)){
            Write-Verbose -Verbose -Message "Will retrieve cipher info"
            $Request = Invoke-WebRequest -Uri $InfoUrl -UseBasicParsing
            $RequestCount = $Request.Content | Measure-Object -Character | Select-Object -ExpandProperty Characters
            if($Request.StatusCode -eq 200 -and ( $RequestCount -ge 100000)){
                Write-Verbose -Verbose -Message "Web Request Status Code: $($Request.StatusCode)"
                Write-Verbose -Verbose -Message "Web Request Content: $($RequestCount) chars $($Request.Content.Substring(0,48))"        
                
                $CipherIntermediary = ($Request.Content | ConvertFrom-Json).ciphersuites
                $CipherList = foreach($c in $CipherIntermediary){
                    $IANA_Name = $c | Get-Member -MemberType noteproperty | Select-Object -ExpandProperty Name 
                    $CipherIntermediary.$IANA_Name | Select-Object -Property @{n="IANA_Name"; e={$IANA_Name}}, *
                }
                #Set-Content -Path $CipherJson -Value $Request.Content
                $CipherList | Export-Csv -Force -Path $CipherCsv -NoTypeInformation
                Write-Verbose "Retrieved info on $($CipherList|Measure-Object | Select-Object -ExpandProperty Count) ciphers."
            }
            else{
                Write-Warning -Message "Web Request Status Code: $($Request.StatusCode)"
                Write-Warning -Message "Web Request Content: $($RequestCount) chars $($Request.Content.Substring(0,48))"
                if(-not $CipherList){Throw "Can't retrieve cipher info nor find any pre-saved"}
            }
        }
    }
    process{
        $Result = foreach($n in $Name){
            $FilterScript = {
                ($_.Iana_Name -like $n) -or
                ($_.Iana_Name -like $n.Replace("_P384","").Replace("_P256","")) -or
                ($_.openssl_name -like $n) -or
                ($_.openssl_name -like $n.Replace("_P384","").Replace("_P256",""))-or
                ($_.gnutls_name -like $n) -or
                ($_.gnutls_name -like $n.Replace("_P384","").Replace("_P256",""))
            }
            $Found = $CipherList | Where-Object -FilterScript $FilterScript
            $FoundCount = $Found | Measure-Object | Select-Object -ExpandProperty Count
            $Props = @{
                "Query" = $n
                "Matches" = $FoundCount
            }
            foreach($f in $Found){
                $Returnable = $Props
                $Returnable."CipherObject" = $f
                $Returnable."Iana Name" = $f.Iana_Name
                $Returnable."Security" = $f.security
                $OutputObj = New-Object -TypeName PSCustomObject -Property $Returnable
                $OutputObj.PsObject.TypeNames.Insert(0, $OutputType)
                $OutputObj
            }
        }
        if($Security){
            $Result | Where-Object -FilterScript {$_.Security -in $Security}
        }
        else{
            $Result
        }
    }
    end{
    }
}
