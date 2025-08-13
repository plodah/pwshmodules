function Get-ADUserAddress {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]
        $City,

        [Parameter()]
        [string[]]
        $StreetAddress,

        [Parameter()]
        [string[]]
        $PostalCode,

        [Parameter()]
        [string[]]
        $Surname,

        [Parameter()]
        [string[]]
        $Forename,

        [Parameter()]
        [string[]]
        $SamAccountName,

        [Parameter()]
        [string[]]
        $Title,

        [Parameter()]
        [int]
        $ReturnCount = 5,

        [Parameter()]
        [string]
        $Server,

        [Parameter()]
        [pscredential]  
        $Credential
    )

    $AdProperties = "Office, StreetAddress","City","PostalCode","Title"
    $AdPropertiesForGrouping = "Office, StreetAddress","City","PostalCode"
    $AdSplat = @{
        Properties = $AdProperties
    }
    if($Server){
        $AdSplat.Server=$Server
    }
    if($Credential){
        $AdSplat.Credential = $Credential
    }
    if(-not ($City -or $StreetAddress -or $PostalCode -or $Surname -or $Forename -or $SamAccountName)){
        throw "Gimme something to work with here"
    }
    if( -not (Get-Command -Name "Get-ADUser" -ErrorAction SilentlyContinue) ){
        Write-Warning "Adding Active Directory Module"
        Import-Module ActiveDirectory
    }
    $QueryParts = New-Object System.Collections.ArrayList
    if($City){
        $QueryPartsCity = New-Object System.Collections.ArrayList
        foreach($cit in $City){
            $QueryPartsCity.Add("City -like `"*$($cit)*`"") | Out-Null
        }
        $QueryParts.Add( "( $($QueryPartsCity -join (') -or (') ) )" ) | Out-Null
    }
    if($StreetAddress){
        $QueryPartsStreetAddress = New-Object System.Collections.ArrayList
        foreach($str in $StreetAddress){
            $QueryPartsStreetAddress.Add("StreetAddress -like `"*$($str)*`"") | Out-Null
        }
        $QueryParts.Add( "( $($QueryPartsStreetAddress -join (') -or (') ) )" ) | Out-Null
    }
    if($PostalCode){
        $QueryPartsPostalCode = New-Object System.Collections.ArrayList
        foreach($pos in $PostalCode){
            $QueryPartsPostalCode.Add("PostalCode -like `"*$($pos)*`"") | Out-Null
        }
        $QueryParts.Add( "( $($QueryPartsPostalCode -join (') -or (') ) )" ) | Out-Null
    }
    if($Surname){
        $QueryPartsSurname = New-Object System.Collections.ArrayList
        foreach($sur in $Surname){
            $QueryPartsSurname.Add("Surname -like `"*$($sur)*`"") | Out-Null
        }
        $QueryParts.Add( "( $($QueryPartsSurname -join (') -or (') ) )" ) | Out-Null
    }
    if($Forename){
        $QueryPartsForename = New-Object System.Collections.ArrayList
        foreach($for in $Forename){
            $QueryPartsForename.Add("GivenName -like `"*$($for)*`"") | Out-Null
        }
        $QueryParts.Add( "( $($QueryPartsForename -join (') -or (') ) )" ) | Out-Null
    }
    if($SamAccountName){
        $QueryPartsSamAccountName = New-Object System.Collections.ArrayList
        foreach($sam in $SamAccountName){
            $QueryPartsSamAccountName.Add("SamAccountName -eq `"$($sam)`"") | Out-Null
        }
        $QueryParts.Add( "( $($QueryPartsSamAccountName -join (') -or (') ) )" ) | Out-Null
    }
    if($Title){
        $QueryPartsTitle = New-Object System.Collections.ArrayList
        foreach($tit in $Title){
            $QueryPartsTitle.Add("Title -like `"*$($tit)*`"") | Out-Null
        }
        $QueryParts.Add( "( $($QueryPartsTitle -join (') -or (') ) )" ) | Out-Null
    }
    $AdSplat.Filter = "( $($QueryParts -join (') -and (') ) )"
    Write-Verbose $AdSplat.Filter
    $AddressesFound = Get-ADUser @AdSplat | 
        Group-Object -Property $AdPropertiesForGrouping |
        Sort-Object -Property count -Descending | 
        Select-Object -first $ReturnCount
    foreach($a in $AddressesFound){
        
        $HashProps = @{
            Office = $a.group[0].Office
            StreetAddress = $a.group[0].StreetAddress
            City = $a.group[0].City
            PostalCode = $a.group[0].PostalCode
            Count = $a.Count
            Valid = [boolean]($a.group[0].StreetAddress -and $a.group[0].City -and $a.group[0].PostalCode)
            Users = $a.group
        }
        $Outputobj = New-Object -TypeName PSCustomObject -Property $HashProps 
        $Outputobj.PsObject.TypeNames.Insert(0,'PlodahPS.ADUserAddress')
        $Outputobj
    } 
}
