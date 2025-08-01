########################################################
##            Something about this module             ##
##                                                    ##
########################################################
## Basic Info;
##    Create a new GUID per module, and give it a description.
$Splattable = @{
    Guid = "00000000-0000-0000-0000-000000000000"
    Author = "plodah"
    CompanyName = "none"
    Description = "This is a dummy description"
}
#Paths. No Change Needed
$RootDir = (Get-Item $PSScriptRoot).Parent
$Splattable.Path = "$($RootDir.FullName)\$($RootDir.Name).psd1"
#ModuleFiles- Enter the filenames to be included. 
$Files = @(
    "Dummy-Cmdlet.psm1"
)
$Splattable.RootModule = ($Files | Select-Object -First 1) 
$Splattable.NestedModules = @( $Files | Select-Object -Skip 1 )
#Cmdlets
$Splattable.CmdletsToExport = @(
    "Get-DummyThing"
)
$Splattable.FunctionsToExport = $Splattable.CmdletsToExport
#Aliases
$Splattable.AliasesToExport = @(
    
)
#Formats
$Splattable.FormatsToProcess = @(
    "Formats\Dummy.Format.ps1xml"
)
#Pre-resquisite modules
$Splattable.RequiredModules = @(
    
)
#ObjectTypes
$Splattable.TypesToProcess = @(
)
#CREATION
New-ModuleManifest @Splattable
