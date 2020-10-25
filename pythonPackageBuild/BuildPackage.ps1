#Requires -Version 6.0
& "$PSScriptRoot\Populatepypirc.ps1"

python setup.py sdist bdist_wheel

twine upload --verbose --skip-existing --config-file /work/.pypirc -r $env:AZURE_DEVOPS_ARTIFACT_REPO_NAME dist/*

Get-ChildItem -Directory | where {$_.name -in ("build","dist") -or $_.name -like "*.egg-info"} | Remove-Item -Recurse