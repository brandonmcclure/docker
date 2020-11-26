$logLevel = 'Debug'
import-module FC_Core, FC_Log

Set-LogLevel $logLevel 
$sourceImage = 'resin/scratch'
docker pull $sourceImage

$repos = @("localhost:5000","registry.mcd.com:5000")

function pushTest($repo){
    Write-Host "testing pushing to $repo"
    docker login $repo 
    $EXEPath = "docker"
    $options = "tag $sourceImage $repo/registry_test"

    $return = Start-MyProcess -EXEPath  $EXEPath -options $options

    if ($logLevel -eq "Debug"){
        #Only show the stdout stream if we are in debugging logLevel
        $return.stdout
    }
    if (-not [string]::IsNullOrEmpty($return.stderr)){
        Write-Log "$($return.stderr)" Warning
        Write-Log "There was an error of some type. See warning above for more info" Error
    }
    elseif ($return.stdout -like '') {
        
    }
}
foreach($repo in $repos){
    pushTest($repo)
}

