# Must enable TFTP in windows: Enable-WindowsOptionalFeature -FeatureName "tftp" -Online
Import-Module ./TestFunctions.psm1
Describe "TFTP Configuration"{
    Context "Input"{

    }
    
    context 'Execution' {
        it 'tftp port is accessible'{

            $result = Test-Port -computer localhost -port 67 -UDP

            if($result.Open -eq $false){
            $result
            throw "port is not open"
            }
        }
        it 'dhcp port is accessible'{

            $result = Test-Port -computer localhost -port 69 -UDP

            if($result.Open -eq $false){
            $result
            throw "port is not open"
            }
        }
    }

    context 'Output' {
    
    }
}