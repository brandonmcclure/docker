See [factorio-docker](https://github.com/factoriotools/factorio-docker) on github for more info. 

I am using docker volumes instead of bind mounts to manage my data. 

To get started, run `docker run --rm -v $($backupDir):/backup --entrypoint /bin/sh -v myfactorio_game_data:/factorio factoriotools/factorio` to create the volume.

Then run the `Backup_game_data.ps1` powershell script to create a gzipped tarbell file of the /factorio directory. Extract that into a folder under the following structure:
backup
- game_data
  - factorio folder structure

This will allow the PS scripts to properly restore the gzipped files into the correct place. 

Then modify the files/folder as needed using the github link above as a guide. I copied over my own save game and mod list so that I could keep playing my existing save. 

Then tar/gzip it up. I used 7zip and just manaually did it. The name should be: `backup-2020-10-13T16-21-28.tar.gz` with the format of YYYY-mm-ddTHH-MM-SS. Move that into the archive path specified in the `restore_game_data.ps1` script. Remove all the factorio containers/volumes and run the restore script. This will pull the most recent gzip file from your archive and update the docker volume with that data. 

run `docker-compose up -d` to start the game server.

You can modify th `game_backup` service in the docker-compose to adjust how frequently these volume backups are run. There is no warning to users when the backup is taken, and I have it configured to shut the game container down when the backup is taken, although that may be overkill.