function Get-VmWareTask
{
    [CmdletBinding()]
    Param(
        [Parameter()]
        [int]
        $LimitMinutes,
        
        [Parameter()]
        [int]
        $RefreshSeconds =  10
    )
    
    if(-not ($Global:DefaultVIServer -or $Global:DefaultVIServers)){
        throw "Not connected to any vCenter Servers."
    }
    $VMSpl = @{"ErrorAction"="SilentlyContinue"}
    
    Write-Warning "I haven't finished this cmdlet yet."
    $StartTime = Get-Date
    if($LimitMinutes){
        $EndTime = $StartTime.AddMinutes($LimitMinutes)
    }
    $CompleteTasks = @()
    do{
        if((Get-Date) -lt $EndTime){Clear-Host}
        $Tasks = Get-Task 
        $FormattedTasks = foreach($t in $Tasks){
            $OutProps = @{
                TaskObj = $t
                Id = $t.id
                Server = $t.ServerId.split("/")[1].split("@:")[1].split(".")[0]
                State = "$($t.State) $($t.PercentComplete)%"
                Start = $t.StartTime
                Finish = $t.FinishTime
                Description = "$($t.ExtensionData.Info.EntityName) - $($t.Description)"
            }
            $OutputObj = New-Object -TypeName PSCustomObject -Property $OutProps
            $OutputObj.PsObject.TypeNames.Insert(0, "PlodahPS.VmTask")
            $OutputObj
        }
        $CompleteTasks += ($FormattedTasks|Where-Object -FilterScript {$_.Finish})
        $CompleteTasks = $CompleteTasks | Group-Object -Property Id | Foreach-Object {$_.group|Select-Object -first 1}
        $RunningTasks = $FormattedTasks|Where-Object -FilterScript {$_.TaskObj.State -eq "Running"}
        $CompleteTasks
        $RunningTasks
        if( (-not $CompleteTasks) -and (-not $RunningTasks)){Write-Verbose -Verbose "No tasks to show"}
        if((Get-Date) -lt $EndTime){Start-Sleep -Seconds $RefreshSeconds}
        if((Get-Date) -ge $EndTime){$StopNow = $true}
    } while(-not $StopNow)
}
