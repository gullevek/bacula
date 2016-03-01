#!/bin/bash

if [ "$1" ];
then
	VERSION=$1;
else
	VERSION="9.4";
fi;

# Modify this according to your setup
DEST=/var/local/backup/postgres/$VERSION/wal

rm -f $DEST/*
rm -f /var/lib/postgresql/$VERSION/backup_in_progress
