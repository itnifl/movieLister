#!/usr/bin/perl -w
#Creator: Atle Holm - atle@team-holm.net

my $configFile = "/etc/movieLister/{name}.conf";
require "./movieLister.pl";

sub initiateConfigFile {
	return $configFile;
}