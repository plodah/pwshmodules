<# .SYNOPSIS Gets file encoding.
.DESCRIPTION The Get-FileEncoding function determines encoding by looking at Byte Order Mark (BOM). Based on port of C# code from http://www.west-wind.com/Weblog/posts/197245.aspx
 
.EXAMPLE
 Get-ChildItem c:\ws\git_repos\COMPONENT_TEMPLATE -recurse -File |
    select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}}
  
$erroractionpreference = 'stop'
  Get-ChildItem c:\ws\git_repos\COMPONENT_TEMPLATE -recurse -File |
    foreach {
        Write-Output $_.FullName
        Get-FileEncoding $_.FullName
    }
      
     This command gets ps1 files in current directory where encoding is not ASCII
  
 .EXAMPLE Get-ChildItem *.ps1 |
     select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} |
         where {$_.Encoding -ne 'ASCII'} foreach {(Get-Content $_.FullName) | set-content $_.FullName -Encoding ASCII}
          
         Same as previous example but fixes encoding using set-content #>
# Modified by F.RICHARD August 2010
# add comment + more BOM
# http://unicode.org/faq/utf_bom.html
# http://en.wikipedia.org/wiki/Byte_order_mark
#
# Do this next line before or add function in Profile.ps1
# Import-Module .\Get-FileEncoding.ps1
#>
function Get-FileEncoding {
    [CmdletBinding()] 
    Param (
        [Alias("FullName")]
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] 
        [string[]]$Path
    )
    begin{
        $OutputType = "PlodahPS.TextEncoding"
    }
    process{
        foreach($p in $Path) {
            Clear-Variable -ErrorAction SilentlyContinue -Name LegacyEncoding,byte
            try {
                if($IsWindows){
                    [byte[]]$Byte = Get-Content -Encoding Byte -ReadCount 4 -TotalCount 4 -LiteralPath $p
                }
                else{
                    [byte[]]$Byte = Get-Content -AsByteStream -ReadCount 4 -TotalCount 4 -LiteralPath $p
                }
                
            } 
            catch {
                throw
            }
            
            Write-Verbose "Bytes: $($Bytes -join " ")"
            if($Byte){
                # EF BB BF (UTF8)  
                # 239 187 191
                if ( $Byte[0] -eq 0xef -and $Byte[1] -eq 0xbb -and $Byte[2] -eq 0xbf ) {
                    $EncodingString = "UTF8"
                }
            
                # FE FF 00 00 (UTF32 Little-Endian) 
                # 254 255 0 0
                elseif ($Byte[0] -eq 0xfe -and $Byte[1] -eq 0xff -and $Byte[2] -eq 0 -and $Byte[3] -eq 0){
                    $EncodingString = "UTF32"
                }
            
                # FE FF (UTF-16 Big-Endian) 
                # 254 255
                elseif ($Byte[0] -eq 0xfe -and $Byte[1] -eq 0xff) {
                    $EncodingString = "BigEndianUnicode"
                }
            
                # FF FE (UTF-16 Little-Endian) 
                # 255 254
                elseif ($Byte[0] -eq 0xff -and $Byte[1] -eq 0xfe) {
                    $EncodingString = "Unicode"
                }
            
                # 00 00 FE FF (UTF32 Big-Endian) 
                # 0 0 254 255
                elseif ($Byte[0] -eq 0 -and $Byte[1] -eq 0 -and $Byte[2] -eq 0xfe -and $Byte[3] -eq 0xff){
                    $EncodingString = "UTF32"
                }
            
                # 2B 2F 76 (38 | 39 | 2B | 2F)  
                # 43 47 118 ( 56 | 57 | 43 | 47 )
                elseif ($Byte[0] -eq 0x2b -and $Byte[1] -eq 0x2f -and $Byte[2] -eq 0x76 -and (
                  $Byte[3] -eq 0x38 -or $Byte[3] -eq 0x39 -or $Byte[3] -eq 0x2b -or $Byte[3] -eq 0x2f) ) {
                    $EncodingString = "UTF7"
                }
            
                # F7 64 4C (UTF-1)  
                # 247 100 76
                elseif ( $Byte[0] -eq 0xf7 -and $Byte[1] -eq 0x64 -and $Byte[2] -eq 0x4c ){
                    $EncodingString = "UTF-1"
                }
            
                # DD 73 66 73 (UTF-EBCDIC) 
                # 221 115 102 115
                elseif ($Byte[0] -eq 0xdd -and $Byte[1] -eq 0x73 -and $Byte[2] -eq 0x66 -and $Byte[3] -eq 0x73) {
                    $EncodingString = "UTF-EBCDIC"
                }
            
                # 0E FE FF (SCSU)
                # 14 254 255
                elseif ( $Byte[0] -eq 0x0e -and $Byte[1] -eq 0xfe -and $Byte[2] -eq 0xff ) {
                    $EncodingString = "SCSU"
                }
            
                # FB EE 28 (BOCU-1)
                # 251 238 40
                elseif ( $Byte[0] -eq 0xfb -and $Byte[1] -eq 0xee -and $Byte[2] -eq 0x28 ) {
                    $EncodingString = "BOCU-1"
                }
            
                # 84 31 95 33 (GB-18030)
                # 132 49 149 51
                elseif ($Byte[0] -eq 0x84 -and $Byte[1] -eq 0x31 -and $Byte[2] -eq 0x95 -and $Byte[3] -eq 0x33){
                    $EncodingString = "BOCU-1"
                }
                
                else {
                    $EncodingString = "ASCII"
                }
            }
            
            else{
                $EncodingString = "Unknown"
            }
            try {
                $EncodingObject = [System.Text.Encoding]::$EncodingString
            }
            catch{
                $EncodingObject = [System.Text.Encoding]::Default
            }
            $Props = @{
                "FileName"      = $p
                "EncodingStr" = $EncodingString
                "EncodingObj" = $EncodingObject
            }
            $OutputObject = New-Object -TypeName PsCustomObject -Property $Props
            $OutputObject.PsObject.TypeNames.Insert(0,$OutputType)
            $OutputObject
        }
    }
    end{
    }
}
