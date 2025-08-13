function Get-VMAttachedIso {
    [CmdletBinding()] 
    param(

        [Parameter( ValueFromPipeline=$true )]
        [string[]]
        $VmName,
        
        [Parameter( ValueFromPipeline=$true )]
        [VMware.VimAutomation.ViCore.Impl.V1.VM.UniversalVirtualMachineImpl[]]
        $VmObj,

        [Parameter( )]
        [string[]] 
        $ISOName,

        [Parameter( )]
        [switch]
        $IncludeEmpty,

        [Parameter( )]
        [switch]
        $IncludeDisconnected

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
                Get-VM @ThisSpl
            }
        }
        if(-not $VmObj){
            $VmObj = Get-VM @VMSpl
        }
        $VMDrives = $VmObj | Sort-Object -Property Name | Get-CDDrive
        if(-not $IncludeEmpty){
            $VMDrives = $VMDrives | Where-Object -FilterScript { $_.IsoPath -or $_.HostDevice -or $_.RemoteDevice -or $_.ExtensionData.DeviceInfo.Summary -eq "Remote device" }
        }
        if(-not $IncludeDisconnected){
            $VMDrives = $VMDrives | Where-Object -FilterScript { $_.ConnectionState.Connected }
        }
        if( $ISOName ){
            $VMDrives = foreach($i in $ISOName){
                $VMDrives | Where-Object -FilterScript { $_.IsoPath -like "*$i*" }
            } 
            $VMDrives = foreach($v in ($VMDrives | Group-Object -Property Id )){ $v.Group | Select-Object -First 1 }
        }
        foreach($v in $VmDrives){
            Clear-Variable -ErrorAction SilentlyContinue -Name SplitIsoPath, DriveNum, OutputObj, Consoles
            try{
                $DriveNum = $v.Name.Split(" ") | Select-Object -Last 1
            }
            catch{ 
                Write-Warning "Something odd happened retrieving Drive Number for $($v.Parent.Name)"
                $DriveNum = 99
            }
            $OutputProps = @{
                VMName          = [string] $v.Parent.Name
                VMGuestName     = [string] $v.Parent.Guest.HostName
                VMHost          = [string] $v.Parent.VMHost.Name
                DriveNum        = [int]    $DriveNum
                DriveName       = [string] $v.Name
                Connected       = $v.ConnectionState.Connected
                DriveObj        = $v
                VmObj           = $v.Parent
            }
            if($v.IsoPath){
                $OutputProps.Type = "ISO"
                $OutputProps.IsoPathRaw = [string] $v.IsoPath
                try{ $SplitIsoPath = $v.IsoPath.split("\/[] ") | Where-Object {$_} }
                catch{ 
                    Write-Warning "Something odd happened retrieving ISO information for $($v.Parent.Name)"
                    $SplitIsoPath = @("???")
                }
                $OutputProps.IsoPath        = [string] ($SplitIsoPath -join "/")
                $OutputProps.IsoName        = [string] ($SplitIsoPath | Select-Object -Last 1)
                $OutputProps.IsoDatastore   = [string] ($SplitIsoPath | Select-Object -First 1)
                $OutputProps.Info           = [string] ($SplitIsoPath | Select-Object -Last 1)
            }
            elseif($v.HostDevice){
                $OutputProps.Type = "Host"
                $OutputProps.Info = [string] $v.Parent.VMHost.Name
            }
            elseif( 
                    ($v.RemoteDevice) -or 
                    ($v.ExtensionData.DeviceInfo.Summary -eq "Remote device") 
                    ){
                $OutputProps.Type = "Client"
                try{
                    $Consoles = (Get-View -VIObject $v.Parent -Property Runtime.NumMksConnections).Runtime.NumMksConnections
                }
                catch{
                    Clear-Variable -Name Consoles -ErrorAction SilentlyContinue
                }
                $OutputProps.Info = [string] "Active sessions: $($Consoles)"
            }
            elseif(-not $v.ConnectionState.Connected){
                $OutputProps.Type = "Empty"
            }
            else{
                Write-Warning "Unknown media source for virtual CD Drive on $($v.Parent.Name). Call NASA?"
            }
            $OutputObj = New-Object -TypeName PSCustomObject -Property $OutputProps
            $OutputObj.PsObject.TypeNames.Insert(0, "PlodahPS.VmAttachedIso")
            $OutputObj
        }
    }
    end{}
}
New-Alias -Name Get-VMIso -Value Get-VMAttachedIso
