# gogextract
Shell script wrapper for innoextract that extracts game files from GOG archives. It is primarily intended for DOS games.

### Usage: ###
Make sure the script is executable:

```chmod 755 gogextract.sh```

The archive to be extracted is the first argument:

```./gogextract.sh setup_gog_game.exe```

`gogextract.sh` will produce an executable `start.sh` script that will launch DOSBox using the configuration file originally contained in the archive. Many of the DOSBox configurations included with GOG games require tweaking or are outright broken, so some additional attention from the user may be needed. 

### To Do ###
macOS compatibility is planned but needs additional testing. 
