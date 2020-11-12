IF(DB_ID(N'AdventureWorksDW2019') IS NULL)
BEGIN
    RESTORE DATABASE AdventureWorksDW2019 
    FROM DISK = '/var/opt/mssql/backup/AdventureWorksDW2019.bak'
    WITH  MOVE 'AdventureWorksDW2017' TO '/var/opt/mssql/data/AdventureWorksDW2019.mdf', 
    MOVE 'AdventureWorksDW2017_log' TO '/var/opt/mssql/data/AdventureWorksDW2019_log.log',
     NOUNLOAD,  STATS = 5
END

IF(DB_ID(N'AdventureWorks2019') IS NULL)
BEGIN
    RESTORE DATABASE AdventureWorks2019 
    FROM DISK = '/var/opt/mssql/backup/AdventureWorks2019.bak'
    WITH  MOVE 'AdventureWorks2017' TO '/var/opt/mssql/data/AdventureWorks2019.mdf', 
    MOVE 'AdventureWorks2017_log' TO '/var/opt/mssql/data/AdventureWorks2019_log.log',
     NOUNLOAD,  STATS = 5
END