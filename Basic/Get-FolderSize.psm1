function Get-FolderSize {
    [CmdletBinding()] 
    param(
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0
        )]          
        $Path = (Get-Location),
        [Parameter( )]
        [Switch]$ShowAll,
        [Parameter( )]
        [Switch]$ShowAudio,
        [Parameter( )]
        [Switch]$ShowVideo,
        [Parameter( )]
        [Switch]$ShowDocs,
        [Parameter( )]
        [Switch]$ShowArchive,
        [Parameter( )]
        [Switch]$ShowOld,
        
        [Parameter( )]
        [ValidateRange(1, 3650)]
        [int]$OldAgeDays = 90,
        [Parameter( )]
        [ValidateRange(1, 15)]
        [int] $RecurseDepth
    )
    begin{
        Test-WindowSize -OutputWidth 133
        if($RecurseDepth){
            $PathObj = foreach($p in $Path){
                Get-Item $p
                Get-ChildItem -Path $p -Directory -Depth ($RecurseDepth - 1)
            }
        }
        else{
            $PathObj = foreach($p in $Path){
                Get-Item $p
            }
        }
        if($ShowOld -or $ShowAll){
            $OldBeforeDate = (Get-Date).AddDays(-$OldAgeDays)
        }
        $FileTypeDictionary = Import-Csv "$Psscriptroot\Source\FileFormats.csv"
        $CheckProps = "AudioCount", "AudioSize", "VideoCount", "VideoSize", "DocumentsCount", "DocumentsSize", "ArchiveCount","ArchiveSize", "OldCount", "OldSize"
        if($ShowAudio -or $ShowVideo -or $ShowDocs -or $ShowAll){
            $OutputType = "PlodahPS.FolderSize.All"
        }
        elseif($ShowOld){
            $OutputType = "PlodahPS.FolderSize.Old"
        }
        else{
            $OutputType = "PlodahPS.FolderSize"
        }
    }
    process{        
        foreach($p in $PathObj){
            Clear-Variable -ErrorAction SilentlyContinue -Name ChildFiles,ChildFilesMeasure,Props
            $ChildFiles = Get-ChildItem -File -Recurse -Path $p
            $ChildFilesMeasure = $ChildFiles | Measure-Object -Property Length -Sum
            $Props = @{
                FullPath = $p.fullname  
                Path = $p.name
                Count = $ChildFilesMeasure.Count
                Size = $ChildFilesMeasure.Sum
            }
            if($ShowArch -or $ShowAll){
                $ArchExts = ($FileTypeDictionary | Where-Object {$_.Type -eq "Archive"}).Extension
                $ArchFiles = $ChildFiles | Where-Object {$_.Extension -in  $ArchExts}
                $ArchFilesMeasure = $ArchFiles | Measure-Object -Property Length -Sum
                $Props.ArchiveCount  = $ArchFilesMeasure.Count
                $Props.ArchiveSize   = $ArchFilesMeasure.Sum
            }
            if($ShowAudio -or $ShowAll){
                $AudioExtensions = ($FileTypeDictionary | Where-Object {$_.Type -eq "Audio"}).Extension
                $AudioFiles = $ChildFiles | Where-Object {$_.Extension -in  $AudioExtensions}
                $AudioFilesMeasure = $AudioFiles | Measure-Object -Property Length -Sum
                $Props.AudioCount  = $AudioFilesMeasure.Count
                $Props.AudioSize   = $AudioFilesMeasure.Sum
            }
            if($ShowDocs -or $ShowAll){
                $DocumentsExtensions = ($FileTypeDictionary | Where-Object {$_.Type -eq "Documents"}).Extension
                $DocumentsFiles = $ChildFiles | Where-Object {$_.Extension -in  $DocumentsExtensions}
                $DocumentsFilesMeasure = $DocumentsFiles | Measure-Object -Property Length -Sum
                $Props.DocumentsCount  = $DocumentsFilesMeasure.Count
                $Props.DocumentsSize   = $DocumentsFilesMeasure.Sum
            }
            if($ShowVideo -or $ShowAll){
                $VideoExtensions = ($FileTypeDictionary | Where-Object {$_.Type -eq "Video"}).Extension
                $VideoFiles = $ChildFiles | Where-Object {$_.Extension -in  $VideoExtensions}
                $VideoFilesMeasure = $VideoFiles | Measure-Object -Property Length -Sum
                $Props.VideoCount  = $VideoFilesMeasure.Count
                $Props.VideoSize   = $VideoFilesMeasure.Sum
            }
            if($ShowOld -or $ShowAll){
                $OldFiles = $ChildFiles | Where-Object {$_.LastWriteTime -le $OldBeforeDate}
                $OldFilesMeasure = $OldFiles | Measure-Object -Property Length -Sum
                $Props.OldCount = $OldFilesMeasure.Count
                $Props.OldSize = $OldFilesMeasure.Sum
            }
            foreach($c in $CheckProps){
                if(-not $Props.$c){$Props.$c = $null}
            }
            $OutputObj = New-Object -TypeName PSCustomObject -Property $Props            
            $OutputObj.PsObject.TypeNames.Insert(0, $OutputType)
            $OutputObj
        }
    }
    end{
    }
}
