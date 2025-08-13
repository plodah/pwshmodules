Function Get-ADUserByMail {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, Position=0, Mandatory=$true)]
        [Alias("EmailAddress")]
        [string[]]    
        $Mail,

        [Parameter()]
        [string]
        $Server,

        [Parameter()]
        [pscredential]
        $Credential,

        [Alias("Property")]
        [Parameter()]
        [string[]]
        $Properties,

        [Parameter()]
        [string]
        $SearchBase,

        [Parameter()]
        [string]
        $Filter,

        [Parameter()]
        [switch]
        $IncludeUPN,

        [Parameter()]
        [switch]
        $IncludeProxyAddresses,

        [Parameter()]
        [switch]
        $IncludeAllMatches
    )
    begin{
        $SplatMe=@{}
        $ExcludeSplat = @("Mail", "Filter", "IncludeUPN", "IncludeProxyAddresses", "IncludeAllMatches","Properties")
        foreach($item in $PSBoundParameters.Keys){
            if($item -notin $ExcludeSplat){
                $SplatMe."$item" = $PSBoundParameters["$item"]
            }
        }
    }
    process{
        foreach($m in $Mail){
            $MailFilter = "mail -like `"$m`""
            $UPNFilter = "UserPrincipalName -like `"$m`""
            $ProxyAddrFilter = "proxyAddresses -like `"$m`""
            if(-not $Properties){
                $Properties = @()
            }
            $Properties += "Mail"
            $ThisFilter = @()
            $ThisFilter += $MailFilter
            if($IncludeUPN -or $IncludeAllMatches){
                $ThisFilter+=$UPNFilter
            }
            if($IncludeProxyAddresses -or $IncludeAllMatches){
                $ThisFilter+=$ProxyAddrFilter
                $Properties += "ProxyAddresses"
            }
            $ThisFilterStr = $ThisFilter -join " -or "
            if($Filter){
                #$SplatMe.Filter = @($Filter, $ThisFilter) -join " -and "
                $SplatMe.Filter = "( $ThisFilterStr ) -and $Filter"
                Write-Verbose $($SplatMe.Filter)
            }
            else{
                $SplatMe.Filter = $ThisFilterStr
            }
            $SplatMe.Properties=$Properties
            Write-Verbose $($SplatMe.Filter)
            Get-ADUser @SplatMe
        }
    }
    end{
    }
}
