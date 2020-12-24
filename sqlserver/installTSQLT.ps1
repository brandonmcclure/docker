param($db = 'container_test',$sa_password = 'weakP@ssword')
Write-Verbose "installing on $db"
/opt/mssql-tools/bin/sqlcmd -S localhost -V16 -U sa -P $sa_password -l 300 -d $db -i installTSQLT.sql