########################################################
##             VmWare Powershell cmdlets              ##
##                                                    ##
########################################################
## Basic Info:
$Splattable = @{
    Guid = "da47f9b1-40f8-4056-bb28-01c47e55b66d"
    Author = "plodah"
    CompanyName = "none"
    Description = "Cmdlets for VmWare"
}
#Paths. No Change Needed
$RootDir = (Get-Item $PSScriptRoot).Parent
$Splattable.Path = "$($RootDir.FullName)\$($RootDir.Name).psd1"
#ModuleFiles
$Files = @(
    "Connect-VmWare.psm1"
    "Get-VMSnapshot.psm1"
    "Get-VmWareTask.psm1"
    "Get-VMAttachedIso.psm1"
)
$Splattable.RootModule = ($Files | Select-Object -First 1) 
$Splattable.NestedModules = @( $Files | Select-Object -Skip 1 )
#Cmdlets
$Splattable.CmdletsToExport = @(
    "Connect-VmWare"
    "Get-VMSnapshot"
    "Get-VmWareTask"
    "Get-VMAttachedIso"
)
$Splattable.FunctionsToExport = $Splattable.CmdletsToExport
#Aliases
$Splattable.AliasesToExport = @(
    "Get-AllSnapshot"
    "Get-VMIso"
)
#Formats
$Splattable.FormatsToProcess = @(
    "Formats/VMSnapshot.Format.ps1xml"
    "Formats/VmTask.Format.ps1xml"
    "Formats/VmAttachedIso.Format.ps1xml"
)
#Pre-resquisite modules
$Splattable.RequiredModules = @(
    
)
#ObjectTypes
$Splattable.TypesToProcess = @(
)
#CREATION
New-ModuleManifest @Splattable
