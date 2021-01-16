
try{
  Import-Module FC_Core,FC_Log,FC_Git,Posh-Git -DisableNameChecking -Force -ErrorAction Stop
}
catch {
  $modulePath = "$($env:BUILD_REPOSITORY_LOCALPATH)\Powershell Scripts\Modules"
  Write-Host "Setting the env:PSModulePath to the same repo: $modulePath"

  if (!(Test-Path $modulePath)) {
    Write-Error "I can't find any Powershell modules in the repo at: $modulePath. I need the modules!"
  }
  else {
    if (!($env:PSModulePath -like "*;$modulePath*")) {
      $env:PSModulePath = $env:PSModulePath + ";$modulePath\"
    }
  }

Import-Module FC_Core,FC_Log,FC_Git,Posh-Git -DisableNameChecking -Force -ErrorAction Stop
}
set-loglevel "Debug"

$Path = $PSScriptRoot
$imageName = "cogito/$((SPlit-Path $Path -Leaf).ToLower())"
Set-Location $PSScriptRoot

docker stop $imageName
docker rm $imageName

Write-Log "Generating basic auth files"

docker run --rm --entrypoint htpasswd registry:2.7.0 -Bbn "$([Environment]::GetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", "User"))" "$([Environment]::GetEnvironmentVariable("DOCKER_REGISTRY_AUTHUSER", "User"))" > htpasswd
#$options = "run --rm --entrypoint htpasswd registry:2.7.0 -Bbn $([Environment]::GetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", "User")) $([Environment]::GetEnvironmentVariable("DOCKER_REGISTRY_AUTHUSER", "User"))"

#Write-Log "options: $options"
#$return = Start-MyProcess -EXEPath "docker " -options $options
#$return.stdout > htpasswd

#[IO.File]::WriteAllText("$PSScriptRoot\htpasswd", ([IO.File]::ReadAllText("$PSScriptRoot\htpasswd") -replace "`r`n", "`n").Trim()+"`n")
if ($logLevel -eq "Debug"){
        #Only show the stdout stream if we are in debugging logLevel
        $return.stdout
    }
    if (-not [string]::IsNullOrEmpty($return.stderr)){
        Write-Log "$($return.stderr)" Warning
        Write-Log "There was an error of some type. See warning above for more info" Error
    }

$registry = [Environment]::GetEnvironmentVariable("DOCKER_REGISTRY", "User")
$tag = "latest"

$oldLocation = Get-Location

Set-Location $path


#$buildImageArtifact = 
$env:DOCKER_BUILDKIT=0 # This set to 1 is needed to pass secrets. To debug, turn this to 0 https://github.com/moby/buildkit/issues/1053 and https://github.com/moby/buildkit/issues/1472

$FQImageName = "$($registry)/$($imageName.ToLower()):$($tag)"
Write-Log "FQImageName: $FQImageName"
docker build -t $FQImageName .

#Invoke-ImageStaticAnalysis  --https://github.com/quay/clair to start
docker push $FQImageName

#docker container run -d --name $($imageName.ToLower()) -p 4567:80 $FQImageName 