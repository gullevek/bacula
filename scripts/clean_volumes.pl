#!/usr/bin/perl

# $Id: clean_volumes.pl 2048 2014-08-08 07:34:04Z root $
# cleans file volumes from bacula backups
# found here:
# http://adsm.org/lists/html/Bacula-users/2011-10/msg00275.html

# define pool dynamic?
# via command line?

use strict;
use Getopt::Long;
use IPC::Open2;
use IO::Handle;

my $bconsole = '/usr/bin/bconsole';
# if not found in bin, look in sbin
if (! -f $bconsole)
{
	$bconsole = '/usr/sbin/bconsole';
}
my (%opts, @purged, $pid);

GetOptions(\%opts,
	'verbose|v',
	'test',
	'dir=s'
);

my ($IN, $OUT) = (IO::Handle->new(), IO::Handle->new());

$pid = open2($OUT, $IN, $bconsole);

if (scalar (@purged = check_volumes()))
{
	printf("Bacula reports the following purged volumes:\n\t%s\n", join("\n\t", @purged)) if ($opts{verbose});
	my ($deleted, $filesize) = delete_volumes(@purged);
	print "$deleted volumes, ".convert_number($filesize)." deleted.\n" if ($opts{verbose});
}
elsif ($opts{verbose})
{
	print "No purged volumes found to delete.\n";
}

print $IN "exit\n";
waitpid($pid, 0);

exit (0);

sub check_volumes
{
	my $dividers = 0;
	my (@purged, @row);

	print $IN "list volumes pool=Scratch\n";
	for (;;)
	{
		my $resp = <$OUT>;
		last if ($resp =~ /No results to list./);
		$dividers++ if ($resp =~ /^[\+\-]+$/);
		last if ($dividers == 3);
		@row = split(/\s+/, $resp);
		push (@purged, $row[3]) if ($row[5] eq 'Purged');
	}

	return (@purged);
}


sub delete_volumes
{
	my $volume_dir = $opts{dir} || '/spool/bacula/';
	my $count = 0;
	my $filesize_sum = 0;

	foreach my $vol (@_)
	{
		my $l;
		my $file = $volume_dir.$vol;

		print "Deleting volume $vol from [catalog: " if ($opts{verbose});
		print $IN "delete volume=$vol yes\n";
		$l = <$OUT>;
		$l = <$OUT>;
		print "OK] [disk: " if ($opts{verbose});
		if (-f $file)
		{
			$count++;
			if ($opts{verbose})
			{
				my $filesize = -s $file;
				$filesize_sum += $filesize;
				print convert_number($filesize)." ";
			}
			unlink ($file) if (!$opts{test});
			print "OK].\n" if ($opts{verbose});
		}
		else
		{
			print "ERRROR: Could not be found in $volume_dir]\n" if ($opts{verbose});
		}
	}

	return ($count, $filesize_sum);
}

# converts bytes to human readable format
sub convert_number
{
	my ($number) = @_;
	my $pos; # the original position in the labels array
	# divied number until its division would be < 1024. count that position for label usage
	for ($pos = 0; $number > 1024; $pos ++)
	{
		$number = $number / 1024;
	}
	# before we return it, we format it [rounded to 2 digits, if has decimals, else just int]
	# and we add the right label to it and return
	return sprintf(!$pos ? '%d' : '%.2f', $number)." ".qw(B KB MB GB TB)[$pos];
}

__END__
