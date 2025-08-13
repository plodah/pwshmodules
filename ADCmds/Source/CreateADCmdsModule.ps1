########################################################
##                      AD CMDs                       ##
##                                                    ##
########################################################
## Basic Info:
$Splattable = @{
    Guid = "c63a17a2-f9b4-4cda-94a8-71ba869ffa98"
    Author = "plodah"
    CompanyName = "none"
    Description = "Additional commands created relating to Active Directory"
}
#Paths. No Change Needed
$RootDir = (Get-Item $PSScriptRoot).Parent
$Splattable.Path = "$($RootDir.FullName)\$($RootDir.Name).psd1"
#ModuleFiles- Enter the filenames to be included. 
$Files = @(
    "Get-ADGroupMembership.psm1"
    "Get-ADLockoutStatus.psm1"
    "Get-ADManager.psm1"
    "Get-ADParentObject.psm1"
    "Get-ADProperty.psm1"
    "Get-ADRecentObject.psm1"
    "Get-ADUserAddress.psm1"
    "Get-ADUserByMail.psm1"
    "Set-ADUserUPNtoMail.psm1"
    "Get-CachedDomainController.psm1"
    "Set-ADUserThumbnailPhoto.psm1"
)
$Splattable.RootModule = ($Files | Select-Object -First 1) 
$Splattable.NestedModules = @( $Files | Select-Object -Skip 1 )
#Cmdlets
$Splattable.CmdletsToExport = @(
    "Get-ADGroupMembership"
    "Get-ADLockoutStatus"
    "Get-ADManager"
    "Get-ADParentObject"
    "Get-ADProperty"
    "Get-ADRecentObject"
    "Get-ADUserAddress"
    "Get-ADUserByMail"
    "Set-ADUserUPNtoMail"
    "Get-CachedDomainController"
    "Set-ADUserThumbnailPhoto"
)
$Splattable.FunctionsToExport = $Splattable.CmdletsToExport
#Aliases
$Splattable.AliasesToExport = @(
    "Get-CachedDC"
)
#Formats
$Splattable.FormatsToProcess = @(
    "Formats/ADGroupMembership.Format.ps1xml"
    "Formats/ADLockoutStatus.Format.ps1xml"
    "Formats/ADProperty.Format.ps1xml"
    "Formats/ADUserAddress.Format.ps1xml"
    "Formats/ADUserUPNtoMail.Format.ps1xml"
    "Formats/CachedDomainController.Format.ps1xml"
)
#Pre-resquisite modules
$Splattable.RequiredModules = @(
    "ActiveDirectory"
)
#ObjectTypes
$Splattable.TypesToProcess = @(
)
#CREATION
New-ModuleManifest @Splattable
