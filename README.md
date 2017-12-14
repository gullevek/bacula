# bacula backup config files

Bacula backup server and client config files.

The work is based on:
https://gist.github.com/mashdot/2312522

Base config is for debian bacula 9.x packages

Differences: uses PostgreSQL, uses auto loader for multiple parallel backups
FIX for 9.x:
If a device was set with multiple jobs > 1 and unique volume names based on the servers then it could happen that some jobs hung with "couldn't open" Volume as other jobs wrote to the same volume.
Setting multiple jobs to 1 fixes this and the normal 1 volume to one client matches.

Things that need to be changed:
Any entry with <> around.
* passwords
* IP/host names
* paths to the backup folder

If backups are done from outside of the network, remember that the SD needs an external host in the current setup, as the FD will access the SD from outside and not vica versa.
