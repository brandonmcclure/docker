
Describe "Pushing Image" {


    context 'Execution' {
        

        it 'Push via localhost'{
            [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHUSER", "basicAuth", "Process")
[Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", "basicAuth", "Process")
[Environment]::SetEnvironmentVariable("DOCKER_CA_AUTHUSER", "basicAuth", "Process")
[Environment]::SetEnvironmentVariable("DOCKER_CA_AUTHPASSWORD", "basicAuth", "Process")
           docker-compose down -v;
           docker-compose up -d
            $logLevel = 'Debug'
import-module FC_Core, FC_Log

Set-LogLevel $logLevel 
$sourceImage = 'resin/scratch'
docker pull $sourceImage

$repos = @("localhost:5000")

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


        }

        it 'Push via registry.domain'{
            [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHUSER", "basicAuth", "Process")
[Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", "basicAuth", "Process")
[Environment]::SetEnvironmentVariable("DOCKER_CA_AUTHUSER", "basicAuth", "Process")
[Environment]::SetEnvironmentVariable("DOCKER_CA_AUTHPASSWORD", "basicAuth", "Process")
            docker-compose down -v;
            docker-compose up -d
            $logLevel = 'Debug'
import-module FC_Core, FC_Log

Set-LogLevel $logLevel 
$sourceImage = 'resin/scratch'
docker pull $sourceImage

$repos = @("registry.mcd.com:5000")

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


        }

    }
}

