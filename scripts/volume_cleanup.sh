#!/bin/bash

# clean up volumes
if [ ! -d ${1} ];
then
	echo "Backup folder could not be found";
	exit 0;
fi;

# move purged to Scratch
/etc/bacula/scripts/move_purged_volumes.pl
# delete from Scratch and from backup folder
/etc/bacula/scripts/clean_volumes.pl -v --dir "${1}";
