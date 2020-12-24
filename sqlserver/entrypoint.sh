#start SQL Server, start the script to restore the DB
 (/init.sh; rc=$?; if [[ $rc != 0 ]]; then echo "init.sh failed with code $rc" && kill $(ps aux | grep 'sqlservr' | awk '{print $2}'); fi) \
  & /opt/mssql/bin/sqlservr