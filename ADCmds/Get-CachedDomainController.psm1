function Get-CachedDomainController {
    [CmdletBinding(DefaultParameterSetName='Auto')]
    param (
        [Parameter()]
        [string[]]        $Server = $env:USERDNSDOMAIN,   
         
        [Parameter()]
        [pscredential]  $Credential,
        [Parameter(ParameterSetName='CacheOnly')]
        [Switch] $CacheOnly,
        [Parameter(ParameterSetName='ForceUpdate')]
        [Switch] $ForceUpdate,
        [Parameter(ParameterSetName='Auto')]
        [uint16] $UpdateIntervalHours = 4,
        [Parameter()]
        [Switch] $DeleteExisting,
        [Parameter()]
        [Switch] $SkipServiceCheck
    )        
    begin{
        $JsonPath="$PSScriptRoot\Source\CachedDomainController.json"
        $CimSessionNoProxy = New-CimSessionOption -ProxyType None  
        if($DeleteExisting){
            [pscustomobject[]]$Known = @()
        }
        else{
            try{
                [pscustomobject[]]$Known = Get-Content $JsonPath | ConvertFrom-Json 
            }
            catch{
                [pscustomobject[]]$Known = @()
            }
        }
    }
    Process{
        foreach($s in $Server){
            Clear-Variable -ErrorAction SilentlyContinue -Name UpdatingDCs
            $ServerParams = @{}
            $CIMParams = @{
                SessionOption = $CimSessionNoProxy
            }
            if($s){
                $ServerParams.Server = $s.ToLower()     
            }
            else{
                $ServerParams.Server = $env:USERDNSDOMAIN.ToLower()
            }
            if($Credential){
                $ServerParams.Credential = $Credential
                $CIMParams.Credential = $Credential
            }
            $KnownThisDomain = $Known | Where-Object {$_.Domain -eq $s.ToLower()} | Sort-Object -Property Updated -Descending | Select-Object -First 1
            if( (-not $CacheOnly) -and ( $ForceUpdate -or ($KnownThisDomain.Updated -and (Get-Date -Date $KnownThisDomain.Updated).AddHours($UpdateIntervalHours) -le (Get-Date)) ) ) {                
                Write-Verbose -Verbose -Message "Updating DC info. Last update was $(Get-Date $KnownThisDomain.Updated). $(if($ForceUpdate){"Update was '-Force'd"})"
                
                $DCQuery = Get-ADDomainController -Filter * @ServerParams | Where-Object {$_.Enabled -and (-not $_.IsReadOnly)}
                if($SkipServiceCheck){
                    $GoodDCs = $DCQuery
                }
                else{
                    $GoodDCs = foreach($d in $DCQuery){
                        Clear-Variable -ErrorAction SilentlyContinue -Name Service,Ping
                        $Ping = Test-Connection -ComputerName $d.HostName -Count 1 -Quiet
                        
                        if($Ping){
                            $ThisCimSess = New-CimSession -ComputerName $d.HostName @CIMParams 
                            if($ThisCimSess){
                                #$Service = Get-CimInstance -Class Win32_Service -Filter "Name = 'ADWS'" -ComputerName $d.HostName @CIMParams -ErrorAction SilentlyContinue
                                $Service = Get-CimInstance -Class Win32_Service -Filter "Name = 'ADWS'" -CimSession $ThisCimSess -ErrorAction SilentlyContinue
                                $ThisCimSess | Remove-CimSession -ErrorAction SilentlyContinue    
                            }
                        }
                        if($Ping -and ($Service.State -eq "Running")){
                            $d
                        }
                    }
                }
                if($GoodDCs){          
                    $UpdatingDCs = $true      
                    [pscustomobject[]]$Discovered = foreach($d in $GoodDCs) {
                        $DCObj = [PSCustomObject] @{
                            ADObject        = $d
                            Name            = [String]      $d.Name
                            HostName        = [String]      $d.HostName
                            Domain          = [String]      $d.Domain
                            IPv4Address     = [String]      $d.IPv4Address
                            Site            = [String]      $d.Site
                            IsDNMaster      = [Boolean]     ($d.OperationMasterRoles -Contains "DomainNamingMaster")
                            IsInfraMaster   = [Boolean]     ($d.OperationMasterRoles -Contains "InfrastructureMaster")
                            IsPDC           = [Boolean]     ($d.OperationMasterRoles -Contains "PDCEmulator")
                            IsRIDMaster     = [Boolean]     ($d.OperationMasterRoles -Contains "RIDMaster")
                            IsSchemaMaster  = [Boolean]     ($d.OperationMasterRoles -Contains "SchemaMaster")
                            IsGC            = [Boolean]     $d.IsGlobalCatalog
                            OSV             = [String]      $d.OperatingSystemVersion.split(" ()")[0]
                            OS              = [string]      $d.OperatingSystem.Replace("Windows Server ","").Replace(" Standard","")
                        }
                        $DCObj.PsObject.TypeNames.Insert(0,'PlodahPS.CachedDomainController')
                        $DCObj
                    }
                    $Entry=[PSCustomObject]@{
                        DCs = $Discovered
                        Updated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        Domain = ($Discovered[0].Domain).ToLower()
                    }
                    $ReturnObj = $Entry
                    $Known = $Known | Where-Object {$_.Domain -ne $Entry.Domain}
                    $Known += $Entry
                }
                else{
                    $ReturnObj = $KnownThisDomain
                }
            }
            else{
                $ReturnObj = $KnownThisDomain
            }
            ##OUTPUT
            Write-Verbose -Verbose -Message "Using Cached DC information from $($ReturnObj.Updated)"
            foreach($k in $ReturnObj.DCs){
                $k.PsObject.TypeNames.Insert(0,'PlodahPS.CachedDomainController')
                $k
            }
        }
    }
    end{
        if($UpdatingDCs){
            $Known | ConvertTo-Json -Depth 9 | Out-File $JsonPath -Encoding UTF8
        }
    }
}
New-Alias -Name Get-CachedDC -Value Get-CachedDomainController
