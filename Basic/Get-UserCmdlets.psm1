function Get-UserCmdlets {
    [CmdletBinding( )]
    Param( )
    
    $AllModule  = Get-Module -ListAvailable |
         Where-Object {$_.path -notlike "*program*files*" -and $_.path -notlike "C:\Windows\System32\*"}
    @(
        foreach ($m in $AllModule){
            Get-Command -Module $m
        } 
    ) | 
        Sort-Object -Property Noun
}
