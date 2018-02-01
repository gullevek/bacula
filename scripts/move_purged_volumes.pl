#!/usr/bin/perl

# Loops through all pools and looks for Purged entries.
# Those entries then get moved to the Scratch pool where
# they will be clean up and the data removed

use strict;

use POSIX qw(floor);
use IPC::Open2;
use IO::Handle;
use Getopt::Long;

binmode STDOUT, ":encoding(utf8)";
binmode STDIN, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

my %opt = ();
my $bconsole = '/usr/sbin/bconsole';
my $pid; # pid from IO
my $dividers = 0; # if dividers are found -> end of listing
my @row; # one row of list data
my @volumes; # list of volumes
my $removed_bytes = 0; # bytes removed
my $test = 0; # flag to 0 for live run
my @exclude_pools = (); # pools to be excluded
my @pools = (); # pools found in bacula, excluding the default exclude list

# default exclude pools
my @exclude_pools_default = qw{Scratch Default DefaultPool};

# if not found in bin, look in sbin
if (! -f $bconsole) {
	$bconsole = '/usr/sbin/bconsole';
}
# exit with error if we do not have bconsole
if (! -f $bconsole) {
	print "Bacula console command could not be found. Is bconsole installed?\n";
	exit 0;
}

# converts bytes to human readable format
sub byte_format {
	my ($number) = @_;
	my $pos; # the original position in the labels array
	# divied number until its division would be < 1024. count that position for label usage
	for ($pos = 0; $number > 1024; $pos ++) {
		$number = $number / 1024;
	}
	# before we return it, we format it [rounded to 2 digits, if has decimals, else just int]
	# we add the right label to it and return
	return sprintf(!$pos ? '%d' : '%.2f', $number)." ".qw(B KB MB GB TB PB EB)[$pos];
}

Getopt::Long::Configure ("bundling");
# the options we can give the program
my $result = GetOptions(\%opt,
	'exclude-pool|e=s' => \@exclude_pools, # which pools to exclude from purge
	'list',
	'test' => \$test,
	'help|h|?'
) || exit 1;

if ($opt{'help'}) {
	print "Options available:\n";
	print "--exclude-pools | -e <pool> [...]\tExclude these pools from purge. Can be given several times\n";
	print "--list\t\t\t\t\tList available pools\n";
	print "--test\t\t\t\t\tDry run, do not move anything in the bacula database\n";
	exit 1;
}

# open the IO handlers
my ($IN, $OUT) = (IO::Handle->new(), IO::Handle->new());
# connect them to the bconsole
$pid = open2($OUT, $IN, $bconsole) || die ("Can't connect to $bconsole");

print "****** [TEST] ******\n" if ($test);
# list available volumes, if --list connect
print $IN "list pools\n";
for (;;) {
	my $resp = <$OUT>;
	# exists
	last if ($resp =~ /No results to list./);
	$dividers ++ if ($resp =~ /^[\+\-]+$/);
	last if ($dividers == 3);
	# split up into the parts & clean up white spaces
	@row = split(/\|/, $resp);
	for (my $i = 0; $i < @row; $i ++) {
		# white space trim
		$row[$i] =~ s/^\s+//g;
		$row[$i] =~ s/\s+$//g;
	}

	# check that 8 (pooltype) is 'Backup' and that 2 (name) is not in the exclude lists
	# if we have --list, the print out result
	my $pool = $row[2];
	if ($row[8] eq 'Backup' && !grep(/^$pool$/, @exclude_pools) && !grep(/^$pool$/, @exclude_pools_default)) {
		push(@pools, $pool);
		print $pool."\n" if ($opt{'list'});
	}
}

# if not list then run the move loop
if (!$opt{'list'}) {
	# loop through each pool
	foreach my $_pool (@pools) {
		$dividers = 0;
		print $IN "list volumes pool=$_pool\n";
		for (;;) {
			my $resp = <$OUT>;
			# exit conditions
			last if ($resp =~ /No results to list./);
			$dividers ++ if ($resp =~ /^[\+\-]+$/);
			last if ($dividers == 3);
			# like in the pool listing split and clean up white spaces
			@row = split(/\|/, $resp);
			for (my $i = 0; $i < @row; $i ++) {
				# white space trim
				$row[$i] =~ s/^\s+//g;
				$row[$i] =~ s/\s+$//g;
			}

			# 2: volume name
			# 3: volume status
			# 5: vol bytes
			# remove any , from the volbytes
			$row[5] =~ s/,//g;
			# write this to an temp array which we use to clean, so we can close down the read command
			push(@volumes, {
				'pool' => $_pool,
				'vol' => $row[2],
				'volstatus' => $row[3],
				'volbytes' => $row[5],
			});
		} # for each volume in pool
	} # for each pool

	# if we have return
	if (@volumes > 0) {
		foreach my $_row (@volumes) {
			my $pool = $_row->{'pool'};
			my $vol = $_row->{'vol'};
			my $volstatus = $_row->{'volstatus'};
			my $volbytes = $_row->{'volbytes'};
			# only work on Purged ones
			if ($volstatus eq 'Purged') {
				if (!$test) {
					print $IN "update volume=$vol pool=Scratch\n";
					print "Move $vol with size ".byte_format($volbytes)." from Pool $pool to Scratch\n";
				} else {
					print "=> TEST MOVE: $vol with size ".byte_format($volbytes)." from Pool $pool to Scratch\n";
				}
				$removed_bytes += $volbytes;
			}
		} # each volume
		print "Space that will be freed: ".byte_format($removed_bytes)."\n";
	} else {
		print "No volumes found in selected pools (".join(', ', @pools).")\n";
	}
} # this is not list

# exit bconsole
print $IN "exit\n";
waitpid($pid, 0);

__END__
