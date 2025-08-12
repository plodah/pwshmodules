########################################################
##                   Basic commands                   ##
##                                                    ##
########################################################
## Basic Info;
$Splattable = @{
    Guid = "aab59dd5-bdf0-4721-8066-31ab40735db3"
    Author = "plodah"
    CompanyName = "none"
    Description = "Basic and miscelanious commands"
}
#Paths. No Change Needed
$RootDir = (Get-Item $PSScriptRoot).Parent
$Splattable.Path = "$($RootDir.FullName)\$($RootDir.Name).psd1"
#ModuleFiles- Enter the filenames to be included. 
$Files = @(
    "BasicObjectCmds.psm1"
    "BasicTextCmds.psm1"
    "Get-CipherSuite.psm1"
    "Get-FileEncoding.psm1"
    "Get-FolderSize.psm1"
    "Get-ModulePath.psm1"
    "Get-UserCmdlets.psm1"
)
$Splattable.RootModule = ($Files | Select-Object -First 1) 
$Splattable.NestedModules = @( $Files | Select-Object -Skip 1 )
#Cmdlets
$Splattable.CmdletsToExport = @(
    # "BasicObjectCmds.psm1"
    "Get-HashTableFromObject"
    "Test-PostCode"
    "Get-UnixTime"
    "Get-WindowSize"
    "Test-WindowSize"

    # "BasicTextCmds.psm1"
    "Write-StupidError"
    "Get-ObjectType"
    "Get-TitleCase"
    "Convert-TimeSpanToString"
    "Get-FileLengthFriendlyString"
    "Remove-QueryFromUrl"
    "Test-UrlString"
    "Get-DadJoke"
    "Test-EmailValidity"
    "Get-PaddedString"

    "Get-CipherSuite"
    "Get-FileEncoding"
    "Get-FolderSize"
    "Get-ModulePath"
    "Add-ModulePath"
    "Set-ModulePath"
    "Optimize-ModulePath"
    "Remove-ModulePath"
    "Get-UserCmdlets"
)
$Splattable.FunctionsToExport = $Splattable.CmdletsToExport
#Aliases
$Splattable.AliasesToExport = @(
    "gt"
    "Get-Type"
)
#Formats
$Splattable.FormatsToProcess = @(
    "Formats/CipherSuite.Format.ps1xml"
    "Formats/FolderSize.Format.ps1xml"
    "Formats/UnixTime.Format.ps1xml"
)
#Pre-resquisite modules
$Splattable.RequiredModules = @(
    
)
#ObjectTypes
$Splattable.TypesToProcess = @(
)
#CREATION
New-ModuleManifest @Splattable
