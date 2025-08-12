function Get-HashTableFromObject {
    param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        [psobject]
        $InputObject 
    )
    $InputObject.psobject.Properties | Where-Object {$_.Value} | ForEach-Object -Begin {$OutputObject = @{}} -Process {$OutputObject[$_.Name] = $_.Value}
    $OutputObject
}

function Test-PostCode {
    param (
        [System.String[]]$PostCode,
        [System.Management.Automation.SwitchParameter]$SuppressWarning,
        $ScottishParliament
    )
    begin{
        $OutputType = "PlodahPS.PostCode"
        #ScotlandURL can provide additional info e.g. scottishparlimentiary constituency
        #$ScotlandURL = "https://api.postcodes.io/scotland/postcodes"
        #$BaseRestURL="https://api.postcodes.io/postcodes"
        $BaseRestURL="https://api.postcodes.io/postcodes"
        $RequestBody= @{ "postcodes" = @( $PostCode ) } | ConvertTo-Json -Compress
        $Result = Invoke-RestMethod -Uri $BaseRestURL -ContentType "application/json" -Method Post -Body $RequestBody
    }
    process{
        foreach($p in $PostCode){
            #$RequestBody= @{ "postcodes" = @( $p ) } | ConvertTo-Json -Compress
            #$Result = Invoke-RestMethod -Uri $BaseRestURL -ContentType "application/json" -Method Post -Body $RequestBody
            $ThisResult = $Result.Result | Where-Object -FilterScript {$_.Query -eq $p}
            
            if($Result.status -eq "200"){
                foreach($res in $ThisResult){
                    if($res.result){
                        $Props = @{
                            "Query"             = $p
                            "Result"            = $ThisResult
                            "PostCode"          = $res.result.postcode
                            "LocalAuthority"    = $res.result.admin_district
                            "Coordinates"       = "$($res.result.latitude), $($res.result.longitude)"
                            "NHS"               = $res.result.nhs_ha
                            "WestministerSeat"  = $res.result.parliamentary_constituency
                            "ElectoralWard"     = $res.result.admin_ward
                        }
                    }
                    else{ 
                        Write-Warning "Postcode $p was not found"
                        $Props = @{
                            "Query"     = $p
                            "Result"    = $ThisResult
                        }
                    }
                    $OutputObject = New-Object -TypeName PsCustomObject -Property $Props
                    $OutputObject.PsObject.TypeNames.Insert(0, $OutputType)
                    $OutputObject
                }
            }
            else{
                Write-Warning "Can't contact api.postcodes.io"
            }
        }
    }
    end{
    }
}
New-Alias -Name Get-PostcodeInfo -Value Test-PostCode

function Get-UnixTime  {
    param(
        [DateTime[]]$DateTime,
        [System.Int32[]]$UnixTime
    )
    $OutputType = "PlodahPS.UnixTime"
    $Epoch = Get-Date -Date "1970-01-01 00:00:00.000000"
    if( (($DateTime | Measure-Object | Select-Object -ExpandProperty Count) + ($UnixTime | Measure-Object | Select-Object -ExpandProperty Count)) -eq 0){
        $DateTime = Get-Date
    }
    $DTObj = foreach($d in $DateTime){
        $Span = New-TimeSpan -Start $Epoch -End $d
        New-Object -TypeName PSCustomObject -Property @{
            "Epoch" = $Epoch
            "DateTime" = $d
            "UnixTIme" = $Span.TotalSeconds
        }
    }
    $UTObj = foreach($u in $UnixTime){
        New-Object -TypeName PSCustomObject -Property @{
            "Epoch" = $Epoch
            "DateTime" = $Epoch.AddSeconds($u)
            "UnixTIme" = $u
        }
    }
    foreach($o in &{$DTObj; $UTObj}){
        $o.PsObject.TypeNames.Insert(0, $OutputType)
        $o
    }
}

function Get-WindowSize {
    [CmdletBinding( )]
    param(

    )
    $OutputObject = New-Object -TypeName PSCustomObject -Property @{
        Width           = [System.Math]::Min( $host.UI.RawUI.BufferSize.Width, $host.UI.RawUI.WindowSize.Width )
        Height          = [System.Math]::Min( $host.UI.RawUI.BufferSize.Height, $host.UI.RawUI.WindowSize.Height )
        BufferWidth     = $host.UI.RawUI.BufferSize.Width
        BufferHeight    = $host.UI.RawUI.BufferSize.Height
        WindowWidth     = $host.UI.RawUI.WindowSize.Width
        WindowHeight    = $host.UI.RawUI.WindowSize.Height
    }
    $OutputObject.PsObject.TypeNames.Insert(0, "PlodahPS.WindowSize")
    $OutputObject
}

function Test-WindowSize {
    [CmdletBinding( )]
    param(
        [parameter(position=0)]
        [System.UInt16]$OutputWidth,

        [parameter()]
        [System.UInt16]$OutputHeight
    )

    if( $OutputWidth -and $host.Name -eq "ConsoleHost" -and ( (Get-WindowSize).Width -lt $OutputWidth ) ){
        Write-Warning "The window might be too narrow for the output"
    }
    
    if( $OutputHeight -and $host.Name -eq "ConsoleHost" -and ( (Get-WindowSize).Height -lt $OutputHeight ) ){
        Write-Warning "The window might be too short for the output"
    }
}