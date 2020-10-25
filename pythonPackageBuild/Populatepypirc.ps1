#Requires -Version 6.0
if ([string]::IsNullOrEmpty($env:AZURE_DEVOPS_ARTIFACT_REPO_NAME)){
  Write-Error "There is no value in enviornment variable: AZURE_DEVOPS_ARTIFACT_REPO_NAME" -ErrorAction Stop
}
if ([string]::IsNullOrEmpty($env:PAT)){
  Write-Error "There is no value in enviornment variable: PAT" -ErrorAction Stop
}
if ([string]::IsNullOrEmpty($env:AZURE_DEVOPS_ARTIFACT_REPO_URL)){
  Write-Error "There is no value in enviornment variable: AZURE_DEVOPS_ARTIFACT_REPO_URL" -ErrorAction Stop
}
"[distutils] 
Index-servers = 
  $env:AZURE_DEVOPS_ARTIFACT_REPO_NAME 
[$env:AZURE_DEVOPS_ARTIFACT_REPO_NAME] 
Repository = $env:AZURE_DEVOPS_ARTIFACT_REPO_URL
username: api  
password: $env:PAT" | Set-Content /work/.pypirc