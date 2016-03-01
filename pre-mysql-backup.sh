#!/bin/bash

DIR=/var/local/backup/mysql
MYSQLCONF=/root/.my.cnf
# those dbs have to be dropped with skip locks (single transaction)
NOLOCKDB="information_schema performance_schema"
NOLOCK="--single-transaction"
# those tables need to be dropped with events
EVENTDB="mysql"
EVENTS="--events"

if [ ! -d "$DIR" ];
then
	mkdir -p $DIR
fi;

# back up all the mysql databases, into individual files so we can later restore
# them separately if needed.
/usr/bin/mysql --defaults-extra-file=$MYSQLCONF -B -N -e "show databases" | while read db
do
	FILE=$DIR/$db.mysql
	echo "Backing up $db into $FILE"
	# lock check
	nolock='';
	for nolock_db in $NOLOCKDB;
	do
		if [ "$nolock_db" = "$db" ];
		then
			nolock=$NOLOCK;
		fi;
	done;
	# event check
	event='';
	for event_db in $EVENTDB;
	do
		if [ "$event_db" = "$db" ];
		then
			event=$EVENTS;
		fi;
	done;

	/usr/bin/mysqldump --defaults-extra-file=$MYSQLCONF $nolock $event --opt $db > $FILE
done
