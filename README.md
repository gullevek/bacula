# bacula backup config files

Bacula backup server and client config files.

The work is based on:
https://gist.github.com/mashdot/2312522

Base config is for debian bacula 7.x packages

Differences: uses PostgreSQL, uses auto loader for multiple parallel backups

Things that need to be changed:
Any entry with <> around.
* passwords
* IP/host names
* paths to the backup folder

If backups are done from outside of the network, remember that the SD needs an external host in the current setup, as the FD will access the SD from outside and not vica versa.
