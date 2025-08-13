Function Get-ADRecentObject {
    [CmdletBinding(DefaultParameterSetName="Last")]
    param(
        [Parameter()]
        [ValidateSet("Object","User","Computer")]
        [string] $ObjectType = "Object",
        [Parameter(ParameterSetName="Last")]
        [ValidateRange(0,999)]
        [int] $Hours,
        [Parameter(ParameterSetName="Last")]
        [ValidateRange(0,999)]
        [int] $Days,
        [Parameter(ParameterSetName="Last")]
        [ValidateRange(0,999)]
        [int] $Weeks,
        [Parameter(ParameterSetName="Last")]
        [ValidateRange(0,999)]
        [int] $Months,
        
        [Parameter(ParameterSetName="After")]
        [datetime] $After,
        [Parameter()]
        [pscredential] $Credential,
        [Parameter()]
        [string[]] $Properties,
        [Parameter()]
        [string] $SearchBase,
        [Parameter()]
        [string] $Server
    )
    $ADSplat = @{}
    foreach($p in $PSBoundParameters.Keys){
        if($p -in @("Credential","Properties","Searchbase","Server")){
            $ADSplat."$p" = $PSBoundParameters["$p"]
        }
    }
    $Now = Get-Date
    if($PSCmdlet.ParameterSetName -eq "After"){
        if($After -lt $Now){
            $CreatedAfter = $After
        }
        else{
            Write-Warning -Message "Date given was in the past or invalid; showing last 30 days"
            $ForceResult = $true
            $Days = 30
        }
    }
    if($PSCmdlet.ParameterSetName -eq "Last" -or $ForceResult){
        if($Hours + $Days + $Weeks + $Months -eq 0){
            Write-Warning -Message "No time input given. Showing last 30 days."
            $Days = 30
        }
        $CreatedAfter = $Now
        if($Hours){     $CreatedAfter = $CreatedAfter.AddHours(-$Hours)}
        if($Days){      $CreatedAfter = $CreatedAfter.AddDays(-$Days)}
        if($Weeks){     $CreatedAfter = $CreatedAfter.AddDays(-($Weeks*7))}
        if($Months){    $CreatedAfter = $CreatedAfter.AddMonths(-$Months)}
    }
    Write-Verbose -Verbose "Will show AD objects created after $(Get-Date -Date $CreatedAfter -Format "yyyy-MM-dd HH:mm")"
    $ADSplat.Filter = {created -ge $CreatedAfter}
    switch($ObjectType){
        "User" {
            Get-ADUser @ADSplat 
        }
        "Computer" {
            Get-ADComputer @ADSplat
        }
        "Object" {
            Get-ADObject @ADSplat
        }
    }
}
