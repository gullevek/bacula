#!/bin/bash

if [ "$1" ];
then
	VERSION=$1;
else
	VERSION="9.6";
fi;

# if the wal files are not bz2 compressed, turn this off here
HAS_COMPRESS=1;
# Modify this according to your setup
DEST=/var/local/backup/postgres/$VERSION/wal

touch /var/lib/postgresql/$VERSION/backup_in_progress
# wait for all bzip2 to be done
if [ "${HAS_COMPRESS}" -eq 1 ];
then
	hold=1;
	while [ "${hold}" -eq 1 ];
	do
		# if there is a file name not txt or any of the valid compressions type, we sleep a second and try again
		if [ -z "$(ls -I '*.bz2' -I '*.gz' -I '*.lzma' -I '*.xz' -I '*.lzo' -I '*.txt' ${DEST})" ];
		then
			hold=0;
		else
			echo "Waiting for WAL compression jobs to finish ...";
			sleep 1;
		fi;
	done;
fi;
