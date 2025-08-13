Function Get-ADManager {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, Position=0)]
        [Alias("User")] 
        [string[]]      
        $Identity,
        [parameter(ValueFromPipeline=$True)]
        #[parameter(ValueFromPipeline=$True, ParameterSetName='Object')]
        [Microsoft.ActiveDirectory.Management.ADObject[]]$ADObject,
        [Alias("Property")]
        [Parameter()]
        [string[]]
        $Properties,
        [Parameter()]
        [switch]
        $Recurse,
        [Parameter()]
        [string]        
        $Server,
        [Parameter()]
        [pscredential]  
        $Credential
    )
    begin{
        $ADSplat = @{}
        if(-not $Properties){
            $Properties = @()
        }
        foreach($p in ("Mail", "Manager", "Title")){
            if($Properties -notcontains $p){
                $Properties += $p
            }
        }
        $ADSplat.Properties = $Properties
        $ForwardParameters = @("Credential","Server")
        foreach($p in $PSBoundParameters.Keys){
            if($p -in $ForwardParameters){
                $ADSplat."$p" = $PSBoundParameters["$p"]
            }
        }
    }
    process{
        if( -not ( &{$Identity; $ADObject})){
            $Identity = $env:USERNAME
        }
        $CheckInput = &{
            foreach($u in $Identity){
                try{Get-ADUser @ADSplat -Identity $u}
                catch{Write-Warning "Can't find user $($u)"}
            }
            foreach($b in $ADObject){
                try{$b|Get-ADUser @ADSplat}
                catch{Write-Warning "Can't find user $($b)"}
            }
        }
        $DisplayMe = $CheckInput | Select-Object -Unique
        foreach($o in $DisplayMe){
            $o
            if($Recurse){$Last = $False}
            else{$Last = $True}
            do{
                if($o.Manager){
                    $o = Get-ADUser @ADSplat $o.Manager
                    $o
                }
                else{
                    $last = $true
                }
            } while(-not $last)
        }
    }
    end{}
}
