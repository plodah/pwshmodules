function Get-StoredPassword {
    [CmdletBinding(DefaultParameterSetName="List")] 
    param(
        [Parameter(ParameterSetName="List")]
        [switch]
        $List,
        
        [Parameter(ParameterSetName="Select",Mandatory=$true)]
        [string]
        $Username,
        
        [Parameter(ParameterSetName="Select")]
        [string]
        $UserDomain=".",
        
        [Parameter(ParameterSetName="Select")]
        [switch]
        $AsPlainText,
        
        [Parameter( )]
        [string]
        $PwDbPath="$PSScriptRoot/Source/StoredPasswords.json",
        
        [Parameter( )]
        [ValidateSet("Pre2000", "UPN", "Unqualified")]
        [string]
        $UsernameFormat = "Pre2000"
    )
    begin{
        $OutputType = 'PlodahPS.StoredPassword'
        if($AsPlainText){ $OutputType = 'PlodahPS.StoredPasswordPlainText' }
        if($List){ $OutputType = 'PlodahPS.StoredPasswordList' }
        $StoredBy = "$($env:USERDOMAIN)\$($env:USERNAME)"
        if(Test-Path $PwDbPath){
            try{
                $PasswordDB = Get-Content $PwDbPath | ConvertFrom-Json 
                $PasswordDB = $PasswordDB | Where-Object -FilterScript {$_.StoredBy -eq $StoredBy}
                #Some reason this does not work on one line.
            }
            catch{
                $PasswordDB = $null
                Write-Error "Password DB exists but wasn't in a valid format. "
            }
        }
        else{
            Write-Error "Password DB does not exist. Create one with New-StoredPassword "
        }
    }
    process{
        if($List){
            foreach($p in $PasswordDB){
                $Props = @{
                    UserDomain = $p.UserDomain
                    UserName = $p.UserName
                    DateModified = $p.DateModified
                }
                $OutputObject = New-Object -TypeName PSCustomObject -Property $Props
                $OutputObject.PsObject.TypeNames.Insert(0,$OutputType)
                $OutputObject
            }
        }
        else{
            $ExistingPassword = $PasswordDB | Where-Object -FilterScript {$_.UserName -eq $UserName -and $_.UserDomain -eq $UserDomain}
            $FoundCount = ($ExistingPassword | Measure-Object | Select-Object -ExpandProperty Count) 
            if( $FoundCount -eq 1){
                try{
                    $ExtractUserName = switch($UsernameFormat){
                        "Pre2000"       { "$($ExistingPassword.UserDomain)\$($ExistingPassword.UserName)" }
                        "UPN"           { "$($ExistingPassword.UserName)@$($ExistingPassword.UserDomain)" }
                        "Unqualified"   { "$($ExistingPassword.UserName)" }
                    }
                    $ExtractPassword = $ExistingPassword.PasswordAsSecureString | ConvertTo-SecureString -ErrorAction SilentlyContinue
                    $ExtractCredential = New-Object -TypeName PSCredential -ArgumentList $ExtractUserName, $ExtractPassword
                }
                catch{
                    Clear-Variable -ErrorAction SilentlyContinue -Name ExtractPassword,ExtractUserName,ExtractCredential
                    Write-Error "Found a stored password but it can't be read"
                }
                if($ExtractCredential){
                    $Props = @{
                        UserName = $ExistingPassword.UserName
                        UserDomain = $ExistingPassword.UserDomain
                        Password = $ExtractPassword
                        FullUserName = $ExtractUserName
                        DateModified = $ExistingPassword.DateModified
                        CredentialObject = $ExtractCredential
                    }
                    if($AsPlainText){
                        $Props.PasswordPlainText = [System.Net.NetworkCredential]::new("", $ExtractPassword).Password
                    }
                    $OutputObject = New-Object -TypeName PSCustomObject -Property $Props
                    $OutputObject.PsObject.TypeNames.Insert(0,$OutputType)
                    $OutputObject
                }
            }
            elseif((-not $FoundCount) -or ($FoundCount -eq 0)){
                Write-Error "No Password found"
            }
            else{
                Write-Error "Multiple results for these details"
            }
        }
    }
    end{
    }
}

function New-StoredPassword {
    [CmdletBinding()] 
    param(
        [Parameter(Mandatory=$true)]
        [string] $Username,
        [Parameter( )]
        [string] $UserDomain=".",
        [Parameter( )]
        [securestring] $Password,
        [Parameter( )]
        [string] $PasswordAsPlainText,
        [Parameter( )]
        [switch] $Overwrite,
        [Parameter( )]
        [string] $PwDbPath="$PSScriptRoot/Source/StoredPasswords.json"
    )
    begin{
        $StoredBy = "$($env:USERDOMAIN)\$($env:USERNAME)"
        if(Test-Path $PwDbPath -ErrorAction SilentlyContinue){
            try{
                $PasswordDB = Get-Content $PwDbPath | ConvertFrom-Json
            }
            catch{
                $PasswordDB = $null
                Write-Warning "Password DB exists but wasn't in a valid format. It'll be overwritten when by any added passwords"
            }
        }
    }
    process{
        if($PasswordDB){
            $ExistingPassword = $PasswordDB | Where-Object -FilterScript {$_.StoredBy -eq $StoredBy -and $_.UserName -eq $UserName -and $_.UserDomain -eq $UserDomain}
            if($ExistingPassword){
                if($Overwrite){
                    Write-Warning "A password with the same details exists, dated $($ExistingPassword.Updated). This is being overwritten."
                    $PasswordDB = $PasswordDB | Where-Object {$_ -ne $ExistingPassword}
                    $ReadyToAdd = $true
                }
                else{
                    Write-Error "A password with the same details exists, dated $($ExistingPassword.Updated). Specify the -Overwrite parameter to replace it"
                    $ReadyToAdd = $false
                }
            }
            else{
                $ReadyToAdd = $true
            }
        }
        else{
            $PasswordDB = @()
            $ReadyToAdd = $true
        }
        if($ReadyToAdd){
            if($PasswordAsPlainText){
                $Password = ConvertTo-SecureString -String $PasswordAsPlainText -AsPlainText -Force
            }
            if(-not $Password){
                $Password = Read-Host -AsSecureString -Prompt "What's the password for $($UserDomain)\$($Username)?"
            }
            $NewPasswordObject = New-Object -TypeName PsCustomObject -Property @{
                StoredBy = $StoredBy
                UserDomain = $UserDomain
                UserName = $Username
                PasswordAsSecureString = $Password | ConvertFrom-SecureString
                DateModified = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            }
            $PasswordDB +=$NewPasswordObject
            $PasswordDBJson = $PasswordDB | ConvertTo-Json
            if(($PasswordDB | Measure-Object | Select-Object -ExpandProperty Count ) -eq 1){
                $PasswordDBJson = "[$PasswordDBJson]"
            }
            $PasswordDBJson | Out-File $PwDbPath -Encoding UTF8
        }
    }
    end{
    }
}

function Remove-StoredPassword {
    [CmdletBinding()] 
    param(
        [Parameter(Mandatory=$true,ParameterSetName="One")]
        [string] $Username,
        [Parameter( )]
        [string] $UserDomain=".",
        [Parameter(Mandatory=$true,ParameterSetName="All")]
        [switch] $All,
        [Parameter( )]
        [string] $PwDbPath="$PSScriptRoot/Source/StoredPasswords.json"
    )
    begin{
        Write-Warning "I haven't finished this cmdlet yet."
        $StoredBy = "$($env:USERDOMAIN)\$($env:USERNAME)"
        if(Test-Path $PwDbPath){
            try{
                $PasswordDB = Get-Content $PwDbPath | ConvertFrom-Json
            }
            catch{
                $PasswordDB = $null
                Write-Warning "Password DB exists but wasn't in a valid format."
            }
        }
    }
    process{
        if($PasswordDB){
            $ExistingPassword = $PasswordDB | Where-Object -FilterScript {$_.StoredBy -eq $StoredBy}
            if(-not $all){
            
                $ExistingPassword = $ExistingPassword | Where-Object -FilterScript {$_.UserName -eq $UserName -and $_.UserDomain -eq $UserDomain}
            }
            if($ExistingPassword){
                $PasswordDB = $PasswordDB | Where-Object -FilterScript {$_ -notin $ExistingPassword}
            }
            else{
            }
        }
        $PasswordDBJson = $PasswordDB | ConvertTo-Json
        if(($PasswordDB | Measure-Object | Select-Object -ExpandProperty Count ) -le 1){
            $PasswordDBJson = "[$PasswordDBJson]"
        }
        $PasswordDBJson | Out-File $PwDbPath -Encoding UTF8
        
    }
    end{
    }
}
