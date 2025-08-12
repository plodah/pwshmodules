function Get-ModulePath {
    [CmdletBinding( )]
    Param( 
        [switch]$SuppressWarnings
    )
    
    $PathSep = [system.io.path]::pathseparator
    $Existing = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine").Split($PathSep) | Sort-Object
    if(-not $SuppressWarnings){
        if( ($Existing | Measure-Object).Count -ne ($Existing | Select-Object -Unique | Measure-Object ).Count){
            Write-Warning "There are duplicate entries in the PSModulePath value. Run Optimize-ModulePath to fix this."
        }
        foreach($e in $Existing){
            Clear-Variable -Name t -Erroraction SilentlyContinue
            $t = Get-Item $e -ErrorAction SilentlyContinue
            if(-not ( $t.exists -and $t.PSIsContainer ) ){
                Write-Warning "Module Path $e does not exist or is not a directory. Either correct this manually or run Optimize-ModulePath to remove the entry."
            }
        }
    }
    $Existing
}
function Add-ModulePath {
    [CmdletBinding( )]
    Param(    
        [parameter ( )]
        [string[]]$Path,
        [parameter ( )]
        [switch]$Force
    )
    begin{
        $PathSep = [system.io.path]::pathseparator
        $Current = Get-ModulePath -SuppressWarnings
        [string[]] $AddMe = @()
    }
    process{
        foreach($p in $Path){
            if($force){
                $AddMe += $Path
            }
            else{
                $t = Get-Item $p -ErrorAction SilentlyContinue
                if($t.exists -and $t.PSIsContainer){
                    if($Current -contains $p){
                        Write-Warning "The path specified is already in PSModulePath."
                    }
                    else{
                        $AddMe += $Path
                    }
                }
                else{
                    Write-Warning "The path specified doesn't exist or is not a directory."
                }
            }
        }
    }
    end{
        if($AddMe){
            $NewValue = $Current+$AddMe | Sort-Object
            $NewValue
            [System.Environment]::SetEnvironmentVariable("PSModulePath", ($NewValue -join $PathSep), "Machine")
        }
        else{
            $Current
        }
    }
}
function Remove-ModulePath {
    [CmdletBinding( )]
    Param(    
        [parameter ( )]
        [string[]]$Path
    )
    begin{
        $PathSep = [system.io.path]::pathseparator
        $Current = Get-ModulePath -SuppressWarnings
        [string[]] $RemoveMe = @()
    }
    process{
        foreach($p in $path){
            if($Current -contains $p){
                $RemoveMe+=$p
            }
            else{
                Write-Warning "The path $p is not in the current PSModulePath list"
            }
        }
    }
    end{
        if($RemoveMe){
            $NewValue = $Current | Where-Object -FilterScript {$_ -notin $RemoveMe}
            $NewValue
            [System.Environment]::SetEnvironmentVariable("PSModulePath", ($NewValue -join $PathSep), "Machine")
        }
        else{
            $Current
        }
    }
}
function Optimize-ModulePath {
    param(
    )
    $PathSep = [system.io.path]::pathseparator
    $Unique = Get-ModulePath -SuppressWarnings | Select-Object -Unique
    [string[]]$Exists = @()
    foreach($u in $Unique){
        $t = Get-Item $u -ErrorAction SilentlyContinue
        if($t.exists -and $t.PSIsContainer){
            $Exists += $u
        }
    }
    $Exists
    [System.Environment]::SetEnvironmentVariable("PSModulePath", ($Exists -join $PathSep), "Machine")
}
function Set-ModulePath {
    [CmdletBinding(DefaultParameterSetName="Live")]
    param (
        [Parameter( Mandatory=$true,
                    ParameterSetName='Live')]
        [switch]
        $Live,
        [Parameter( Mandatory=$true,
                    ParameterSetName='Dev')]
        [switch]
        $Dev
    )
    $LivePath = "C:\Mtemp\PwshSharedModules"
    $DevPath = "C:\Mtemp\PwshDevModules\MLPwshModules"
    $EnvPaths = Get-ModulePath -Source Environmental    | Select-Object -Unique 
    $RegPaths = Get-ModulePath -Source Registry         | Select-Object -Unique 
    $EnvIndex = $EnvPaths.IndexOf( ($EnvPaths | Where-Object {$_ -like "C:\Mtemp\*"} ) )
    $RegIndex = $RegPaths.IndexOf( ($RegPaths | Where-Object {$_ -like "C:\Mtemp\*"} ) )
    
    if($Live){
        $EnvPaths[$EnvIndex] = $LivePath
        $RegPaths[$RegIndex] = $LivePath
    }
    elseif($Dev){
        $EnvPaths[$EnvIndex] = $DevPath
        $RegPaths[$RegIndex] = $DevPath
    }
    $EnvPaths = $EnvPaths | Sort-Object
    $RegPaths = $RegPaths | Where-Object {$_ -notlike "C:\Users\*"} | Sort-Object
    $env:PSModulePath = ($RegPaths -join ";")
    Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -Name PSModulePath -Value ($EnvPaths -join ";")
}
