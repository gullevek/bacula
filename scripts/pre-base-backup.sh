#!/bin/bash

# first paramter is the version, used to find the correct binary
if [ "$1" ];
then
	VERSION=$1;
else
	VERSION="9.4";
fi;

# second parameter is port, if set use this, else ignore it
if [ "$2" ];
then
	PORT=" -p $2";
else
	PORT='';
fi;

su - postgres -c "/usr/lib/postgresql/$VERSION/bin/psql$PORT -c \"select pg_start_backup('Full_Backup', true);\""
