#!/usr/bin/env perl

$|=1;

use FindBin;
use lib $FindBin::Dir . "/../lib"; 

use strict;
use warnings;

use DDGC;
use DDGCTest::Database;
use File::Path qw( make_path remove_tree );
use String::ProgressBar;

use Getopt::Long;

my $config = DDGC::Config->new;

my $kill;
my $start;

GetOptions (
	"kill"  => \$kill,
	"start" => \$start,
);

if (-d $config->rootdir_path) {
  if ($kill) {
    remove_tree($config->rootdir_path);
    if ($config->db_dsn =~ m/^dbi:Pg:/) {
      if ($config->db_dsn =~ m/database=([\w\d]+)/) {
        my $db = $1;
        my $userarg = length($config->db_user) ? "-U ".$config->db_user : "";
        system("dropdb $userarg ".$db);
        system("createdb $userarg ".$db);
      } else {
        die "Can't find out your db name from DSN";
      }
    }
  } else {
    die "environment exist, use --kill to kill it!";
  }
}

print "\n";
print "Generating development environment, this may take a while...\n";
print "============================================================\n";
print "\n";
print "Deploying fresh environment into ".$config->rootdir_path."\n";
print "Deploying database structure to dsn '".$config->db_dsn."'\n";
print "\n";

my $ddgc = DDGC->new({ config => $config });

my $pr; 

DDGCTest::Database->new($ddgc,0,sub {
  print "\n";
  print "Filling database with test data\n";
  print "\n";
	$pr = String::ProgressBar->new(
    max => shift,
    length => 60,
    bar => '#',
    show_rotation => 1,
    print_return => 0,
  );
	$pr->write;
},sub {
	$pr->update(shift);
	$pr->write;
})->deploy;

print "\n\n";
print "done... You can start the development webserver with:\n\n";
print "script/ddgc_web_server.pl -r -d\n";
print "\n";
