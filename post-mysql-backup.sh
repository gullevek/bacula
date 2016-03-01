#!/bin/bash

DIR=/var/local/backup/mysql

if [ -d "$DIR" ];
then
	rm -f $DIR/*;
fi;
