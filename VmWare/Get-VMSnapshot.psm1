function Get-VMSnapshot {
    [CmdletBinding(DefaultParameterSetName='DaysHours')] 
    param(
        [Parameter( ValueFromPipeline=$true )]
        [string[]]
        $VmName,
        [Parameter(ParameterSetName='DaysHours')]
        [int] 
        $AgeDays = 0,
        [Parameter(ParameterSetName='DaysHours')]
        [int] 
        $AgeHours = 0,
        [Parameter(ParameterSetName='Timespan')]
        [System.TimeSpan] 
        $AgeTimeSpan,
        [Parameter( )]
        [switch]
        $IncludeRestorePoints,
        
        [Parameter( ValueFromPipeline=$true )]
        [VMware.VimAutomation.ViCore.Impl.V1.VM.UniversalVirtualMachineImpl[]]
        $VmObj
    )
    begin{
        if(-not ($Global:DefaultVIServer -or $Global:DefaultVIServers)){
            throw "Not connected to any vCenter Servers."
        }
        $VMSpl = @{"ErrorAction"="SilentlyContinue"}
    }
    process{
        if( $VmName ){
            $VmObj += foreach($v in $VmName){
                $ThisSpl = $VMSpl
                $ThisSpl.Name = $VmName
                Get-VM  @ThisSpl
            }
        }
        if(-not $VmObj){
            $VmObj = Get-VM @VMSpl
        }
        $Snapshots = $VmObj | Get-Snapshot | Sort-Object -Property VM
    
        if(-not $IncludeRestorePoints){
            $Snapshots = $Snapshots | Where-Object -FilterScript {$_.name -notlike "Restore Point *"}
        }
        $UseTime = Get-Date
        if(-not $AgeTimeSpan){
            $AgeTimeSpan = New-TimeSpan -Days $AgeDays -Hours $AgeHours
        }
        $BeforeDate = $UseTime - $AgeTimeSpan
        if($AgeTimeSpan -ge 1){
            $Snapshots = $Snapshots | Where-Object -FilterScript {$_.created -le $BeforeDate}
        }
    
        foreach($s in $Snapshots){
            $OutProps = @{
                VMObj = $s.Vm
                SnapObj = $s
                VM = $s.vm.Name
                Name = $s.Name.replace("%2f","/")
                Description = $s.Description
                Created = $s.Created #(Get-Date -Date $s.Created -Format "yyyy-MM-dd HH:mm")
                PowerState = $s.PowerState
                Size = "{0:n1}" -f $s.SizeGB
            }
            $OutputObj = New-Object -TypeName PSCustomObject -Property $OutProps
            $OutputObj.PsObject.TypeNames.Insert(0, "PlodahPS.VmSnapshot")
            $OutputObj

        }
    }
    end{}
}
New-Alias -Name Get-AllSnapshot -Value Get-VMSnapshot
