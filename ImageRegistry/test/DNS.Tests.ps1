$domain = "mcd.com"
Import-Module ./TestFunctions.psm1
$Script:domain = "mcd.com"
Describe "DNS Configuration"{
    Context "Input"{
        it 'config file is valid json'{
            $x = Get-Content ../config/config.json -ErrorAction Stop
            $json = ConvertTo-Json -InputObject $x -Depth 5 -ErrorAction Stop
            
            If ([string]::IsNullOrEmpty($json)){
                throw "config/config.json is not valid json"
            }
        }
    }

    context 'Execution' {
        it 'registry.domain is accessible'{
              # Step 1. Create a username:password pair
            $credPair = "$([Environment]::GetEnvironmentVariable("DOCKER_REGISTRY_AUTHUSER", "Process")):$([Environment]::GetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", "Process"))"
 
            # Step 2. Encode the pair to Base64 string
            $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))

            # Step 3. Form the header and add the Authorization attribute to it
            $headers = @{ Authorization = "Basic $encodedCredentials" }
            Invoke-RestMethod https://registry.$($Script:domain):5000/v2/_catalog -Method GET -Headers $headers
            
        }
        it 'grafana.domain is accessible'{
          
          Invoke-WebRequest https://grafana.$($Script:domain):3000
          
      }
      it 'dns port is accessible'{

        $result = Test-Port -computer localhost -port 53 -UDP

        if($result.Open -eq $false){
        $result
        throw "port is not open"
    }
    }
    }
    context 'Output' {
    
    }
}