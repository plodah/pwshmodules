Function Get-ADProperty {
    [CmdletBinding(DefaultParameterSetName="Identity")]
    param(
        [Parameter(ValueFromPipeline, Position=0, Mandatory=$true, ParameterSetName="Identity")]
        [Alias("SamAccountName")]
        [string[]] $Identity,
        
        [Parameter()]
        [string[]] $Properties,
        [Parameter(ValueFromPipeline, Mandatory=$true, ParameterSetName="Object")]
        [Microsoft.ActiveDirectory.Management.ADObject[]] $AdObject,
        [Parameter()]
        [string] $Server,
        [Parameter()]
        [pscredential] $Credential
    )
    $ADSplat = @{}
    if($Server){$ADSplat.Server = $Server}
    if($Credential){$ADSplat.Credential = $Credential}
    
    if($Identity){
        $AdObject = foreach($i in $Identity){
            #Write-Warning "identity:$i"
            Get-AdObject -Filter {  (samaccountname -like $i) -or (userprincipalname -like $i) -or (mail -like $i) } @AdSplat
        }
    }
    foreach($ado in $AdObject){
        #Write-Warning "object:$($ado.samaccountname)"
        Clear-Variable -ErrorAction SilentlyContinue -Name FullObject, FullObjectProperties, FullObjectType
        $FullObject = $ado | Get-AdObject -Properties * @AdSplat
        $FullObjectType = Get-Type -Object $FullObject
        $FullObjectProperties = $FullObject | Get-Member | Where-Object -FilterScript {$_.Membertype -eq "Property"} 
        if($Properties){
            $SelectedProperties = foreach($P in $Properties){
                $FullObjectProperties | Where-Object -FilterScript {$_.Name -like "$P"}
            }
        }
        else{$SelectedProperties = $FullObjectProperties}
        $SelectedProperties = $SelectedProperties | Sort-Object -Property "Name"  | Select-Object -Unique
        foreach($Sel in $SelectedProperties){
            Clear-Variable -ErrorAction SilentlyContinue -Name Props
            $Props = @{
                "SamAccountName"    = $FullObject.SamAccountName
                "ADObjectType"      = $FullObject.ObjectClass
                "PSObjectType"      = $FullObjectType
                "PropertyName"      = $Sel.name
                "PropertyType"      = $Sel.Definition.split(" ")[0]
                "PropertyValue"     = $fullobject[$Sel.name]
            }
            $Outputobj = New-Object -TypeName PsCustomObject -Property $Props
            $Outputobj.PsObject.TypeNames.Insert(0,'PlodahPS.ADProperty')
            $Outputobj
        }
    }
}
