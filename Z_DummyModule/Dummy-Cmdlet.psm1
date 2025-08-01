function Get-DummyThing {
    [CmdletBinding()] 
    param(
        [Parameter( )]
        [ValidateSet("abc","def")]
        [string] $Name,
    
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [Alias("Server")] 
        [string[]]$ComputerName = 'localhost',
        [Parameter( )]
        [PSCredential]  $Credential
    )
    begin{
        $OutputType = "PlodahPS.Dummy"
        Write-Warning "I haven't written this cmdlet yet."
    }
    process{
        [PSCustomObject]$OutputObj=@{
            Name="Hello"
        }
        $OutputObj.PsObject.TypeNames.Insert(0, $OutputType)
        $OutputObj
    }
    end{
    }
}
