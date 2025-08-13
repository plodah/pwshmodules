function New-ThumbnailPhoto {
    param(
        [parameter(ParameterSetName="Path",Mandatory=$true)]
        $ImagePath,
        [parameter(ParameterSetName="Object",Mandatory=$true)]
        [System.Drawing.Image]
        $Image,
        [int]
        $SizePx=400
    )
    Write-Warning "I'm just fannying about, this doesn't do anything yet"
        Add-Type -AssemblyName System.Drawing
        if($PSCmdlet.ParameterSetName -eq "Path"){
            $Image = [System.Drawing.Image]::FromFile((Get-Item $ImagePath))
        }
        $Aspect = $Image.Width / $Image.Height
        if($aspect -ge 1){
            $WidthOut = $SizePx
            $HeightOut = $SizePx / $Aspect
        }
        else{
            $HeightOut = $SizePx
            $WidthOut = $SizePx * $Aspect
        }
        $ImageOut = New-Object System.Drawing.Bitmap($WidthOut,$HeightOut)
        $graph = [System.Drawing.Graphics]::FromImage($ImageOut)
	    $graph.DrawImage($Image, 0, 0, $WidthOut, $HeightOut)
        return $ImageOut
}

function Set-ADUserThumbnailPhoto {
    param (
        [Parameter()]
        [string]
        $Identity,

        [Parameter()]
        [string]
        $Path,

        [Parameter()]
        [string]
        $Server,

        [Parameter()]
        [pscredential]
        $Credential
    )
    
    $ADSplat=@{}
    if($Server){
        $ADSplat.Server = $Server
    }
    if($Credential){
        $ADSplat.Credential = $Credential
    }
    try{
        $UserObj = Get-ADUser -Identity $Identity @ADSplat
    }
    catch{
        $UserObj=$null
        Write-Error "Can't fund $Identity"
    }
    if( -not (Get-Command -Name "Get-ADUser" -ErrorAction SilentlyContinue) ){
        Write-Warning "Adding Active Directory Module"
        Import-Module ActiveDirectory
    }
    Write-Warning "I'm just fannying about, this doesn't do anything yet"
    $Image = New-ThumbnailPhoto -ImagePath $Path
    
	try {
		$Bytes = [System.Drawing.ImageConverter]::new().ConvertTo($Image, [byte[]])
		$UserObj | Set-ADUser -Replace @{thumbnailPhoto=$Bytes} @ADSplat
	}
	catch {
		Write-Error "Something went wrong, couldn't add photo for $Identity"
	}
}
