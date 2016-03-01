#!/bin/bash

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

# (more) secure umask
umask 0027

backup_repo() {
	dir=$1
	repo=$2

	# find out last revision for repository
	youngest=`svnlook youngest $dir`

	# Full dump, save last revision for next incrementals
	if [ ! -f "$dumptarget/$repo.full.bz2" ] || [ "$level" == "Full" ];
	then
		echo "Full dump of $repo (rev. $youngest)"
		svnadmin dump -q "$dir" | bzip2 -c > "$dumptarget/$repo.full.bz2"
		echo $youngest > "$dumptarget/$repo.last"
		rm -f "$dumptarget/$repo.inc.bz2"

	# Inremental backup if last revision in full dump found
	elif [ -f $dumptarget/$repo.last ];
	then
		previous=`cat $dumptarget/$repo.last`
		oldest=$(($previous + 1))
		if [ ! "$previous" == "$youngest" ];
		then
			echo "Incremental dump of $repo (rev. ${oldest}-${youngest})"
			svnadmin dump -q --revision $oldest:$youngest --incremental "$dir" | bzip2 -c > "$dumptarget/$repo.inc.bz2"
		else
			echo "No changes in $repo (rev. ${youngest})"
			return 1
		fi
	else
		echo "Error : did not find last dumped revision ($repo.last file)" >&2
		exit 1
	fi
}

if $single_repo;
then
	backup_repo "$svnroot" "repository"
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
			backup_repo "$d" "`basename $d`"
		fi;
	done
fi

exit 0
