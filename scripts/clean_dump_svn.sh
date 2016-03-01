#!/bin/bash

# Script is run after Bacula backup finished data dump
# removes all data except the $repo.last file

# paths to the svn root and where backups get dumped
svnroot=/var/lib/subversion
dumptarget=/var/local/backup/subversion_dump

# if you don't have multiple repos, set this to true
single_repo=false
# space seperated list of repos to skip
exclude_repo='administration'

if [ -n "$1" ];
then
	level=$1
	[ "$level" == "Base" ] && level=Full
else
	echo "Error : No Job level specified" >&2
	echo "Usage: `basename $0` [Base|Full|Incremental|Differential|Since]"
	exit 1
fi

umask 0027

clean_backup_repo() {
	dir=$1
	repo=$2;
	if [ "$level" == "Full" ];
	then
		backup_file="$repo.full.bz2";
	else
		backup_file="$repo.inc.bz2";
	fi;
	rm -f "$dumptarget/$backup_file";
	# and touch create, so we have a dummy file for next run if it is full
	if [ "$level" == "Full" ];
	then
		touch "$dumptarget/$backup_file";
	fi;
}

if $single_repo;
then
	clean_backup_repo "$svnroot" "repository"
else
	for d in `find $svnroot -mindepth 1 -maxdepth 1 -type d -name '[a-z]*'`;
	do
		exclude=0;
		for excl_repo in $exclude_repo;
		do
			if [ "`basename $d`" = "$excl_repo" ];
			then
				exclude=1;
			fi;
		done;
		if [ $exclude -eq 0 ];
		then
			clean_backup_repo "$d" "`basename $d`"
		fi;
	done
fi

exit 0
