#!/usr/bin/perl

use strict;
use Cwd;

sub _fork_and_exec {
	my ($file) = @_;
	my $pid = fork();
	if ($pid == -1) {
		die;
	} elsif ($pid == 0) {
		#print "chdir to $file\n";
		chdir($file);
		if (-e "$file/Makefile") {
			system("make -j install > /dev/null");
		}
		exit;
	}
}

sub _go_into_dir {
	my ($dir) = @_;
	foreach my $file (<$dir/*>) {
		if ($file =~ "plugins\$") {
			_go_into_dir($file);
		} elsif (-d $file) {
			_fork_and_exec($file);
		}
	}
	# print "done\n";
}


my $cwd = getcwd();
# These are independant of anything but need to be compiled before anything outside of common/api/db_api
_fork_and_exec("$cwd/src/database");
_fork_and_exec("$cwd/src/bcast");

#print "chdir to common\n";
chdir("$cwd/src/common");
system("make -j install > /dev/null");
#print "chdir to api\n";
chdir("$cwd/src/api");
system("make -j install > /dev/null");
#print "chdir to db_api\n";
chdir("$cwd/src/db_api");
system("make -j install > /dev/null");
#print "done with serial\n";

_go_into_dir("$cwd/src");

if ($ARGV[0]) {
	_fork_and_exec("$cwd/contribs");
	_fork_and_exec("$cwd/doc");
}

while (wait() != -1) {}
#system("make -j install > /dev/null");
#print "really done\n";
system("sync");
