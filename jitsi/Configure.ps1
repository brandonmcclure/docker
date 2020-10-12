#Requires -Version 7.0
# https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker
# You need to git clone https://github.com/jitsi/docker-jitsi-meet and then copy this script into the git repo. Run this script with your settings and then docker-compose up

$HTTPPort = "80"
$HTTPSPort = "443"
$RESTART_POLICY = 'no'
$LetsEncryptEnable = $false
$LetsEncryptEmail = ''
$LetsEncryptDomain = ''
$CONFIG_PATH = '/jitsi-meet-cfg'

# Create Secure Passwords in the config
function generatePassword() {
    
    function Get-RandomCharacters($length, $characters) { 
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length } 
    $private:ofs="" 
    return [String]$characters[$random]
}
    function Scramble-String([string]$inputString){     
        $characterArray = $inputString.ToCharArray()   
        $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
        $outputString = -join $scrambledStringArray
        return $outputString 
    }

    $password = Get-RandomCharacters -length 16 -characters 'abcdefghiklmnoprstuvwxyzABCDEFGHKLMNOPRSTUVWXYZ1234567890!-_'
    
   Write-Output (Scramble-String($password) | ConvertTo-SecureString -AsPlainText -Force)
}

$JICOFO_COMPONENT_SECRET=$(generatePassword)
$JICOFO_AUTH_PASSWORD=$(generatePassword)
$JVB_AUTH_PASSWORD=$(generatePassword)
$JIGASI_XMPP_PASSWORD=$(generatePassword)
$JIBRI_RECORDER_PASSWORD=$(generatePassword)
$JIBRI_XMPP_PASSWORD=$(generatePassword)

$filePath = "$($PSScriptRoot)\env.example"
$tempFilePath = "$env:TEMP\$($filePath | Split-Path -Leaf)"

function replaceWith{
    
  [cmdletbinding()]
param(
    [parameter(ValueFromPipeline)]
    $string,
$find = 'foo',
$replace = 'bar'
)
PROCESS {
    $outVal = $string -replace $find, $replace
    Write-Output $outVal
}
}

$content = Get-Content -Path $filePath
$content | replaceWith -find "JICOFO_COMPONENT_SECRET=" -replace "JICOFO_COMPONENT_SECRET=$(ConvertFrom-SecureString $JICOFO_COMPONENT_SECRET -AsPlainText  )"`
| replaceWith -find "JICOFO_AUTH_PASSWORD=" -replace "JICOFO_AUTH_PASSWORD=$(ConvertFrom-SecureString $JICOFO_AUTH_PASSWORD -AsPlainText  )"`
| replaceWith -find "JVB_AUTH_PASSWORD=" -replace "JVB_AUTH_PASSWORD=$(ConvertFrom-SecureString $JVB_AUTH_PASSWORD -AsPlainText  )"`
| replaceWith -find "JIGASI_XMPP_PASSWORD=" -replace "JIGASI_XMPP_PASSWORD=$(ConvertFrom-SecureString $JIGASI_XMPP_PASSWORD -AsPlainText  )"`
| replaceWith -find "JIBRI_RECORDER_PASSWORD=" -replace "JIBRI_RECORDER_PASSWORD=$(ConvertFrom-SecureString $JIBRI_RECORDER_PASSWORD -AsPlainText  )"`
| replaceWith -find "JIBRI_XMPP_PASSWORD=" -replace "JIBRI_XMPP_PASSWORD=$(ConvertFrom-SecureString $JIBRI_XMPP_PASSWORD -AsPlainText  )"`
| foreach-object{if (-not [string]::IsNullOrEmpty($HTTPPort)){$_ | replaceWith -find "HTTP_PORT=8000" -replace "HTTP_PORT=$HTTPPort"}else{$_}}`
| foreach-object{if (-not [string]::IsNullOrEmpty($HTTPSPort)){$_ | replaceWith -find "HTTPS_PORT=8443" -replace "HTTPS_PORT=$HTTPSPort"}else{$_}}`
| foreach-object{if (-not [string]::IsNullOrEmpty($RESTART_POLICY)){$_ | replaceWith -find "RESTART_POLICY=unless-stopped" -replace "RESTART_POLICY=$RESTART_POLICY"}else{$_}}`
| foreach-object{if (-not [string]::IsNullOrEmpty($CONFIG_PATH)){$_ | replaceWith -find "CONFIG=~/.jitsi-meet-cfg" -replace "CONFIG=$CONFIG_PATH"}else{$_}}`

| foreach-object{if ($LetsEncryptEnable){$_ | replaceWith -find "#ENABLE_LETSENCRYPT=1" -replace "ENABLE_LETSENCRYPT=1"}else{$_}}`
| foreach-object{if ($LetsEncryptEnable){$_ | replaceWith -find "#LETSENCRYPT_DOMAIN=meet.example.com" -replace "LETSENCRYPT_DOMAIN=$LetsEncryptDomain"}else{$_}}`
| foreach-object{if ($LetsEncryptEnable){$_ | replaceWith -find "#LETSENCRYPT_EMAIL=alice@atlanta.net" -replace "LETSENCRYPT_EMAIL=$LetsEncryptEmail"}else{$_}}`
| Add-Content -Path $tempFilePath

Remove-Item -Path "$(Split-Path $filePath -Parent)\.env" -ErrorAction Ignore
Move-Item -Path $tempFilePath -Destination "$(Split-Path $filePath -Parent)\.env" -Force

# Create CONFIG directories

New-Item -Path "$($PSScriptRoot)\jitsi-meet-cfg\web\letsencrypt" -ItemType Directory -Force
New-Item -Path "$($PSScriptRoot)\jitsi-meet-cfg\transcripts" -ItemType Directory -Force
New-Item -Path "$($PSScriptRoot)\jitsi-meet-cfg\prosody\config" -ItemType Directory -Force
New-Item -Path "$($PSScriptRoot)\jitsi-meet-cfg\prosody\prosody-plugins-custom" -ItemType Directory -Force
New-Item -Path "$($PSScriptRoot)\jitsi-meet-cfg\jicofo" -ItemType Directory -Force
New-Item -Path "$($PSScriptRoot)\jitsi-meet-cfg\jvb" -ItemType Directory -Force
New-Item -Path "$($PSScriptRoot)\jitsi-meet-cfg\jigasi" -ItemType Directory -Force
New-Item -Path "$($PSScriptRoot)\jitsi-meet-cfg\jibri" -ItemType Directory -Force
