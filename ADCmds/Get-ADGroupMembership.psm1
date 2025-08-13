Function Get-ADGroupMembership {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, Position=0)]
        [Alias("User")] 
        [string[]]      
        $Identity = $env:username,
        [Parameter()]
        [string[]]
        $Filter,
        [Parameter()]
        [string]        
        $Server,
        [Parameter()]
        [pscredential]  
        $Credential
    )
    begin{
        if( -not (Get-Command -Name "Get-ADUser" -ErrorAction SilentlyContinue) ){
            Import-Module ActiveDirectory
        }
        $ADSplat = @{}
        foreach($p in $PSBoundParameters.Keys){
            if($p -in @("Credential","Server")){
                $ADSplat."$p" = $PSBoundParameters["$p"]
            }
        }
    }
    process{
        foreach($I in $Identity){
            Clear-Variable UserObj,ErrorOccurred,groups -ErrorAction SilentlyContinue
            if($I.GetType().Name -eq "ADUser"){
                $UserObj = $I | Get-ADUser -Properties MemberOf @ADSplat
            }
            elseif($I.GetType().Name -eq "String"){
                try{
                    $UserObj = Get-ADUser -Identity $I -Properties MemberOf @ADSplat
                }
                catch{
                $HashProps=@{
                    User            = $I
                    GroupCategory   = "Error"
                    Name            = "Can't Find this User"
                }
                    $GroupObj = New-Object -TypeName PsCustomObject -Property $HashProps
                    $GroupObj.PsObject.TypeNames.Insert(0,'PlodahPS.AdGroupMembership')
                    $GroupObj
                    $ErrorOccurred = $true
                }
            }
            if(!$ErrorOccurred){
                $Groups = $UserObj.memberOf | Get-ADGroup @ADSplat | Sort-Object -Property SamAccountName
                if($Filter){
                    $Groups = Foreach($f in $Filter){
                        $Groups | Where-Object -FilterScript {$_.samaccountname -like "*$f*"}
                    }
                    $Groups = $Groups | Group-Object -Property samaccountname | Foreach-Object {$_.Group | Select-Object -First 1} | Sort-Object -Property samaccountname
                }
                foreach($g in $Groups){
                    Clear-Variable GroupObj -ErrorAction SilentlyContinue
                    $HashProps=@{
                        GroupCategory       = $g.GroupCategory
                        GroupScope          = $g.GroupScope
                        Name                = $g.Name
                        SamAccountName      = $g.SamAccountName
                        User                = $UserObj.SamAccountName
                        GroupCategoryStr    = $g.GroupCategory.ToString().SubString(0,8)
                        GroupScopeStr       = $g.GroupScope.ToString().SubString(0,4)
                    }
                    $GroupObj = New-Object -TypeName PsCustomObject -Property $HashProps
                    $GroupObj.PsObject.TypeNames.Insert(0,'PlodahPS.AdGroupMembership')
                    $GroupObj
                }
            }
        }
    }
}
