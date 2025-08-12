function New-Password {
    [CmdletBinding()]
    param(
        [Parameter( )]
        [int]
        $Length=20,
        
        [Parameter( )]
        [switch]
        $IncludeAmbiguousCharacters,
        
        [Parameter( )]
        [switch]
        $ExcludeSymbols,
        
        [Parameter( )]
        [switch]
        $ExcludeNumbers,
        
        [Parameter( )]
        [switch]
        $ExcludeUpperCase,
        
        [Parameter( )]
        [switch]
        $ExcludeLowerCase,
        
        [Parameter( )]
        [string]
        $ExtraCharacters="",
        
        [Parameter( )]
        [string]
        $Suffix="",
        
        [Parameter( )]
        [string]
        $Prefix=""
    )
    $UpperUnAmb = "ABCDEFGHJKLMNPRTUVWXYZ"
    $UpperAmb = "IOQS"
    $LowerUnAmb = "abcdefghijkmnopqrstuvwxyz"
    $LowerAmb = "l"
    $NumbersUnAmb = "123456789"
    $NumbersAmb = "0"
    $Symbols = "!£$%^&*-=_+"

    $UseLetters=$ExtraCharacters

    if(-not $ExcludeUpperCase){
        $UseLetters+=$UpperUnAmb
        if($IncludeAmbiguousCharacters){
            $UseLetters+=$UpperAmb
        }
    }
    if(-not $ExcludeLowerCase){
        $UseLetters+=$LowerUnAmb
        if($IncludeAmbiguousCharacters){
            $UseLetters+=$LowerAmb
        }
    }
    if(-not $ExcludeNumbers){
        $UseLetters+=$NumbersUnAmb
        if($IncludeAmbiguousCharacters){
            $UseLetters+=$NumbersAmb
        }
    }
    if(-not $ExcludeSymbols){
        Write-Verbose "Including Symbols $Symbols"
        $UseLetters+=$Symbols
    }
    Write-Verbose "Character Set is $UseLetters"
    $RandomNumbers = 1..$length|Foreach-Object {Get-Random -Maximum $UseLetters.Length}
    #Write-Warning $UseLetters
    
    "$Prefix$(($UseLetters[$RandomNumbers]) -join '')$Suffix"
}
