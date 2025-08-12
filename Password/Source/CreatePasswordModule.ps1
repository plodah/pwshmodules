########################################################
##              Stuff handling passwords              ##
##                                                    ##
########################################################
## Basic Info;
$Splattable = @{
    Guid = "e19e320b-2bdc-432a-b5b5-30cc07ef57fa"
    Author = "plodah"
    CompanyName = "none"
    Description = "Work with stored passwords as securestrings"
}
#Paths. No Change Needed
$RootDir = (Get-Item $PSScriptRoot).Parent
$Splattable.Path = "$($RootDir.FullName)\$($RootDir.Name).psd1"
#ModuleFiles- Enter the filenames to be included.  
$Files = @(
    "New-Password.psm1"
    "Get-StoredPassword.psm1"
)
$Splattable.RootModule = ($Files | Select-Object -First 1) 
$Splattable.NestedModules = @( $Files | Select-Object -Skip 1 )
#Cmdlets
$Splattable.CmdletsToExport = @(
    "New-Password"
    "Get-StoredPassword"
    "New-StoredPassword"
    "Remove-StoredPassword"
)
$Splattable.FunctionsToExport = $Splattable.CmdletsToExport
#Aliases
$Splattable.AliasesToExport = @(
    
)
#Formats
$Splattable.FormatsToProcess = @(
    "Formats/StoredPassword.Format.ps1xml"
)
#Pre-resquisite modules
$Splattable.RequiredModules = @(
    
)
#ObjectTypes
$Splattable.TypesToProcess = @(
)
#CREATION
New-ModuleManifest @Splattable
