function Connect-VmWare {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string[]]
        $Server,
        [Parameter()]
        [pscredential]
        $Credential
    )

    $Param = @{}
    if($Credential) {
        $Param.Credential = $Credential
    }

    <#
        Stripped some hardcoded server names from this cmdlet.
        Without them, this feels a bit redundant, barely improving on Connect-VIServer (if at all)
        The point was originally to connect to 2+ vcenters as a one-liner, without typing their fqdn's.
        Should perhaps support this from a config file or global variable 
    #>
    
    foreach($s in $Server) {
        Try {
            Write-Warning "Connecting to $s"
            Connect-VIServer $s @Param
        }
        Catch {
            $Param.Credential = Get-Credential
            Connect-VIServer $s @Param
        }
    }

}
