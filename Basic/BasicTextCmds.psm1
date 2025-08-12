function Get-ObjectType {
    param(
        [ValidateNotNullOrEmpty()]
        [parameter( Mandatory=$true, ValueFromPipeline=$true )]
        [psobject]
        $Object
    )
    begin{ }
    process{
        foreach($o in $Object){
            $o.GetType()|Select-Object -ExpandProperty FullName
        }
    }
    end{ }
}
New-Alias -Name Get-Type -Value Get-ObjectType
New-Alias -Name gt -Value Get-ObjectType

function Write-StupidError {
    param(
        [System.String]$Message
    )
    $StupidColours="Red","DarkRed","Yellow","DarkYellow","Green","DarkGreen","Cyan","DarkCyan","Blue","DarkBlue","Magenta","DarkMagenta"
    Foreach($c in $StupidColours){
        $redidmessage=$message
        $fc =  $StupidColours[ ($StupidColours.IndexOf($c) +5) % $StupidColours.count  ]
        #$Padding = [System.Math]::Round((($Host.UI.RawUI.WindowSize.Width) - $Message.Length), 2) /2 
        $Padding = [System.Math]::Round(( (Get-WindowSize) -0.1  - $Message.Length ) /2 ) 
        1..$Padding | Foreach-Object{
            $redidmessage= " " + $redidmessage + " " 
        }
        Write-Host $redidmessage -BackgroundColor $c -ForegroundColor $fc
    }
}

function Get-TitleCase{
    param(
        [System.String]$Name,
        [System.Management.Automation.SwitchParameter]$IgnoreMc,
        [System.String[]]$ExtraDictionary
    )
    $Textinfo = (Get-Culture).TextInfo
    $Symbols = Import-Csv -Path "$PSScriptRoot\Source\ExtraSymbols.csv"
    $SplitOn = " $($Symbols.Symbol -join '')"
    $IntermediateA = $Name.Trim().ToLower()
    foreach($s in $Symbols){ 
        $IntermediateA = $IntermediateA.Replace("$($s.Symbol)", "$($s.Symbol)$($s.Replacement)$($s.Symbol)") 
    }
    $SplitName = $IntermediateA.Split($SplitOn)
    #$SplitName = $Name.Trim().ToLower().Replace("-","_Dash_-").Split(" -").Trim()
    [System.String[]]$OutputName=@()
    $OutputName = foreach($n in $SplitName){
        $NLen = $n | Measure-Object -Character | Select-Object -ExpandProperty Characters
        if($n -in $ExtraDictionary){
            $ExtraDictionary | Where-Object -FilterScript {$_ -eq $n}
        }
        elseif( ($NLen -ge 3) -and (-not $IgnoreMc) -and $n.Substring(0,2) -eq "mc"){
             "$($TextInfo.ToTitleCase($n.substring(0,2)))$($TextInfo.ToTitleCase($n.substring(2)))"
        }
        elseif( ($NLen -ge 4) -and (-not $IgnoreMc) -and $n.Substring(0,3) -eq "mac"){
            "$($TextInfo.ToTitleCase($n.substring(0,3)))$($TextInfo.ToTitleCase($n.substring(3)))"
        }
        elseif( ($NLen -ge 3) -and (-not $IgnoreMc) -and $n.Substring(0,2) -eq "o'"){
            "$($TextInfo.ToTitleCase($n.substring(0,2)))$($TextInfo.ToTitleCase($n.substring(2)))"
        }
        else{
            $TextInfo.ToTitleCase($n)
        }
    }
    $IntermediateB = $OutputName -join " "
    foreach($s in $Symbols){ 
        $IntermediateB = $IntermediateB.Replace(" $($s.Replacement) ", "$($s.Symbol)")
        $IntermediateB = $IntermediateB.Replace("$($s.Replacement) ", "$($s.Symbol)")
        $IntermediateB = $IntermediateB.Replace(" $($s.Replacement)", "$($s.Symbol)")
        $IntermediateB = $IntermediateB.Replace("$($s.Replacement)", "$($s.Symbol)")
    }
    #return ($OutputName -join " " ).Replace("_Dash_ ","-")
    return $IntermediateB
}

function Convert-TimeSpanToString([System.TimeSpan]$t){
    "$($t.days) $('{0:d2}' -f ($t.hours)):$('{0:d2}' -f $t.minutes)"
}

function Get-FileLengthFriendlyString{
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [System.UInt64]$Length
    )
    if($Length -ge (1MB*1PB)){
        "$("{0:n1}" -f ($Length / (1MB*1PB)) ) ZB"
    }
    elseif($Length -ge (1KB*1PB)){
        "$("{0:n1}" -f ($Length / (1KB*1PB)) ) EB"
    }
    elseif($Length -ge 1PB){
        "$("{0:n1}" -f ($Length / 1PB) ) PB"
    }
    elseif($Length -ge 1TB){
        "$("{0:n1}" -f ($Length / 1TB) ) TB"
    }
    elseif($Length -ge 1GB){
        "$("{0:n1}" -f ($Length / 1GB) ) GB"
    }
    elseif($Length -ge 1MB){
        "$("{0:n1}" -f ($Length / 1MB) ) MB"
    }
    elseif($Length -ge 1KB){
        "$("{0:n1}" -f ($Length / 1KB) ) KB"
    }
    else{
        "$Length B"
    }
}

function Remove-QueryFromUrl{
    [CmdletBinding()]
    param(
        [System.Uri]$Uri
    )
    [System.Uri]"$($Uri.Scheme)$([System.Uri]::SchemeDelimiter)$($Uri.Authority)$($Uri.AbsolutePath)"
}

function Test-UrlString{
    param(
        [System.Uri]$Uri
    )
    if(-not ($Uri.Scheme -and $Uri.Authority -and $Uri.IsAbsoluteUri)){
        [System.Uri]$UriFix="http://$Uri"
        if($UriFix.Scheme -and $UriFix.Authority -and $UriFix.IsAbsoluteUri){
            $Uri=$UriFix
        }
    }
    $Uri
}

function Get-DadJoke {
    param(
        $Proxy
    )
    try{
        $joke=Invoke-WebRequest https://icanhazdadjoke.com -Proxy $Proxy -Headers @{ACCEPT="text/plain"}|Select-Object -expand content
    }
    catch{
        $joke="Do you know any good jokes?"
    }
    $joke
}

function Test-EmailValidity {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]
        $EmailAddress
    )
    try{
        $EmailObj = [mailaddress]::new($EmailAddress)
        $validMail=$true
    }
    catch{
        Write-Verbose "$EmailAddress is invalid"
    }
    
    if( -not (Resolve-DnsName -Type mx -Name $EmailObj.host -ErrorAction SilentlyContinue)){
        $validMail=$false
    }
    return [boolean]$validMail
}

function Get-PaddedString {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]
        $Input,
        [Parameter()]
        [int]
        $Length,
        [Parameter()]
        [string]
        $PadString = " ",
        [Parameter()]
        [switch]
        $Truncate,
        [Parameter()]
        [string]
        $TruncationString
    )
    $InputLength = $Input | Measure-Object -Character | Select-Object -ExpandProperty Characters
    $TruncationStringLength = 0
    if(-not $Length){$Length = $InputLength}
    $WorkingStr = $Input
    if($InputLength -gt $Length -and $Truncate){
        if($TruncationString){
            $TruncationStringLength = $TruncationString | Measure-Object -Character | Select-Object -ExpandProperty Characters   
        }
    }
    if($InputLength -lt $Length){
        $WorkingStr = $Input
        $PadStringLength = $PadString | Measure-Object -Character | Select-Object -ExpandProperty Characters   
        1..(($Length - $InputLength)/$PadStringLength) | foreach{
            $WorkingStr += $PadString
        }
    }
    return $WorkingStr.Substring(0, ($Length - $TruncationStringLength)) + $TruncationString
}
