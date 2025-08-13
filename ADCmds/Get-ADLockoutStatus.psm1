function Get-ADLockoutStatus {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, Position=0, Mandatory=$true)]
        [string[]]      $User,
        [Parameter()]
        [string]        $Server = $env:USERDNSDOMAIN,
        [Parameter()]
        [System.Management.Automation.PSCredential]  $Credential
    )
    begin {
        if( -not (Get-Command -Name "Get-ADUser" -ErrorAction SilentlyContinue) ){
            Write-Warning "Adding Active Directory Module"
            Import-Module ActiveDirectory
        }
        $ServerParams = @{}
        $IndividualServerParams = @{}
        if($Server){
            $ServerParams.Server = $Server.ToLower()
        }
        else{
            $ServerParams.Server = $env:USERDNSDOMAIN.ToLower()
        }
        if($Credential){
            $ServerParams.Credential = $Credential
            $IndividualServerParams.Credential = $Credential
        }
        $ADProperties = @{ Properties = ("LockedOut","LastBadPasswordAttempt","PasswordLastSet","AccountLockoutTime","badPwdCount","LastLogonDate","lastLogon","lastLogonTimestamp") }
        $DomainControllers = Get-CachedDomainController @ServerParams
        
        if($DebugPreference -eq "Continue"){
            foreach($d in $DomainControllers){
                $ADWS = Get-Service -Name ADWS -ComputerName $d.hostname 
                Write-Debug "$($d.name) - $($ADWS.StartType) - $($ADWS.Status)"
            }
        }
    }
    process{
        $UserObjs = New-Object System.Collections.ArrayList
        foreach($u in $User){
            try{
                $UserObjs.Add((Get-ADUser -Identity $u @ServerParams)) | Out-Null
            }
            catch{
                Write-Warning "Can't find $u"
            }
        }
        foreach($u in $UserObjs){
            foreach($d in $DomainControllers){
                Clear-Variable -ErrorAction SilentlyContinue -Name ADResult,Outputobj
                $ADResult = $u | Get-ADUser -Server $d.HostName @ADProperties @IndividualServerParams
                $Outputobj=[pscustomobject] @{
                    Username            = $u.samaccountname
                    DomainController    = $d.name
                    PDC                 = $d.IsPDC
                    State               = $ADResult.LockedOut
                    LockoutTime         = $ADResult.AccountLockoutTime
                    LastBadPass         = $ADResult.LastBadPasswordAttempt
                    BadPassCount        = $ADResult.badPwdCount
                    PassLastSet         = $ADResult.PasswordLastSet
                    LastLogonDate       = $ADResult.LastLogonDate
                    LastLogon           = [datetime]::FromFileTime($ADResult.LastLogon)
                    LastLogonTS         = [datetime]::FromFileTime($ADResult.LastLogonTimeStamp)
                }
                $Outputobj.PsObject.TypeNames.Insert(0,'PlodahPS.ADLockoutStatus')
                $Outputobj
            }
        }
    }
}