#!/usr/bin/perl -w
#Creator: Atle Holm - atle@team-holm.net
use strict;

my $dbUser = getDbUser();
my $dbPassword = getDbPassword();
my $configFile = getConfigFile();
my $cid = getConfsetID($configFile);
if($cid < 0) {
	setConfsetDB($configFile);
	$cid = getConfsetID($configFile);
}

sub setConfsetDB {
	my $cf = shift;
	my $confname = shift;
	$confname = $cf if(!defined($confname));
	my ($dbh, $sth);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database at setConfsetDB(): $DBI::errstr\n";	
	$sth=$dbh->prepare("INSERT INTO movie_repositories_table(name, confset) VALUES( ".$dbh->quote($confname).", ".$dbh->quote($cf).");") || die "Prepare failed at setConfsetDB(): $DBI::errstr\n";
	my $success = $sth->execute() || die "Couldn't execute query: $DBI::errstr at setConfsetDB()\n";
	my $result = ($success ? $dbh->commit : $dbh->rollback);
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
	return ($success ? 1 : 0);
}
sub enableDBConfset {
	my $dbConfset = shift;
	my ($dbh, $sth);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database at enableDBConfset(): $DBI::errstr\n";	
	$sth=$dbh->prepare("UPDATE movie_repositories_table SET state=1 WHERE confset=".$dbh->quote($dbConfset).";") || die "Prepare failed at enableDBConfset(): $DBI::errstr\n";
	my $success = $sth->execute() || die "Couldn't execute query: $DBI::errstr at enableDBConfset()\n";
	my $result = ($success ? $dbh->commit : $dbh->rollback);
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
	return $result;
}
sub disableDBConfset {
	my $dbConfset = shift;
	my ($dbh, $sth);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database at disableDBConfset(): $DBI::errstr\n";	
	$sth=$dbh->prepare("UPDATE movie_repositories_table SET state=0 WHERE confset=".$dbh->quote($dbConfset).";") || die "Prepare failed at disableDBConfset(): $DBI::errstr\n";
	my $success = $sth->execute() || die "Couldn't execute query: $DBI::errstr at disableDBConfset()\n";
	my $result = ($success ? $dbh->commit : $dbh->rollback);
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
	return $result;
}
sub deleteDBConfset {
	my $dbConfset = shift;
	my ($dbh, $sth);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database at disableDBConfset(): $DBI::errstr\n";	
	$sth=$dbh->prepare("DELETE from movie_repositories_table WHERE confset=".$dbh->quote($dbConfset).";") || die "Prepare failed at disableDBConfset(): $DBI::errstr\n";
	my $success = $sth->execute() || die "Couldn't execute query: $DBI::errstr at disableDBConfset()\n";
	my $result = ($success ? $dbh->commit : $dbh->rollback);
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
	return $result;
}
sub updateDBRepoComment {
	my $dbConfset = shift;
	my $comment = shift;
	my ($dbh, $sth);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || return [0, "Error opening database at updateDBRepoComment(): $DBI::errstr\n"];	
	$sth=$dbh->prepare("UPDATE movie_repositories_table SET comments=".$dbh->quote($comment)." WHERE confset=".$dbh->quote($dbConfset).";") || return [0, "Prepare failed at updateDBRepoComment(): $DBI::errstr\n"];
	my $success = $sth->execute() || return [0, "Couldn't execute query: $DBI::errstr at updateDBRepoComment()\n"];
	my $result = ($success ? $dbh->commit : $dbh->rollback);
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
	return [$result, $result];
}
sub setBitRateDB {
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my $data = shift;
	my $filename = shift;
	my @fileNameSplit = split('/', $filename);
	my $path = substr $filename, 0, (length($filename) - length($fileNameSplit[((scalar @fileNameSplit)-1)]));
	$filename = $fileNameSplit[((scalar @fileNameSplit)-1)];
	my ($dbh, $sth);
	my $success = 1;
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";	

	checkFileAndPathsInCacheTable($filename, $path);
	my $exists = checkFileMovieRelation($movieName, $filename);
	if (!$exists) {
		$sth=$dbh->prepare("INSERT INTO movie_files_table(bitrate, movie_id, cache_id) SELECT ".$dbh->quote($data).", mi.id, mc.id FROM movie_info_table mi, movie_cache_table mc WHERE mi.name=".$dbh->quote($movieName)." AND mc.filename=".$dbh->quote($filename). ";") || die "Prepare failed: $DBI::errstr\n";
		$sth->execute() || die "Couldn't execute query: $DBI::errstr at setBitRateDB()\n";
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	} else {
		$sth=$dbh->prepare("UPDATE movie_files_table mf LEFT JOIN movie_info_table mi ON mf.movie_id = mi.id LEFT JOIN movie_cache_table mc ON mf.cache_id = mc.id SET mf.bitrate=".$dbh->quote($data)." WHERE (mf.movie_id=mi.id) AND mi.name=".$dbh->quote($movieName)." AND mc.filename=".$dbh->quote($filename). ";") || die "Prepare failed: $DBI::errstr\n";
		$success &&= $sth->execute() || die "Couldn't execute query: $DBI::errstr at setBitRateDB()\n";
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
}
sub setMovieInfoSearched {
	#Sets if movie is googled already for movie info
	my $movieName = shift;
	my $searched = shift;
	#print "Received " . $searched ."\n";
	$searched = 1 if(!defined($searched) || !intCheck($searched));
	$searched = 1 if($searched > 0);
	$searched = 0 if($searched < 0);
	$movieName = nameProcessor($movieName);
	my $success = 1;
	my ($dbh, $sth);
	
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$sth=$dbh->prepare("UPDATE movie_info_table SET searched='".$searched."' WHERE name=". $dbh->quote($movieName) .";") || die "Prepare failed: $DBI::errstr at setMovieInfoSearched()\n";;
	$success = $sth->execute() || die "Couldn't execute query: $DBI::errstr at setMovieInfoSearched()\n";
	my $result = ($success ? $dbh->commit : $dbh->rollback);
	unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr . " at setMovieInfoSearched()"}
	#print "Updated with " . $searched ."\n";
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
}
sub setMovieFileSearched {
	#Sets if movie is googled already for movie info
	my $filename = shift;
	my @fileNameSplit = split('/', $filename);
	$filename = $fileNameSplit[((scalar @fileNameSplit)-1)];
	my $success = 1;
	my ($dbh, $sth);
	
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$sth=$dbh->prepare("UPDATE movie_files_table mf LEFT JOIN movie_cache_table mc ON mf.cache_id=mc.id SET mf.searched='1' WHERE mc.filename=". $dbh->quote($filename) .";") || die "Prepare failed: $DBI::errstr at setMovieFileSearched()\n";
	$success = $sth->execute() || die "Couldn't execute query: $DBI::errstr at setMovieFileSearched()\n";
	my $result = ($success ? $dbh->commit : $dbh->rollback);
	unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr . " at setMovieFileSearched()"}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
}
sub setResolutionDB {
	my $movieName = shift;
	my $data = shift;
	my $filename = shift;
	my @fileNameSplit = split('/', $filename);
	my $path = substr $filename, 0, (length($filename) - length($fileNameSplit[((scalar @fileNameSplit)-1)]));
	$filename = $fileNameSplit[((scalar @fileNameSplit)-1)];
	my ($dbh, $sth);
	$movieName = nameProcessor(lc($movieName));
	my $exists = checkFileMovieRelation($movieName, $filename);
	my $success = 1;
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr at setResolutionDB()\n";	
	checkFileAndPathsInCacheTable($filename, $path);
	
	$exists = checkFileMovieRelation($movieName, $filename);
	if (!$exists) {
		$sth=$dbh->prepare("INSERT INTO movie_files_table(quality, movie_id, cache_id) SELECT ".$dbh->quote($data).", mi.id, mc.id FROM movie_info_table mi, movie_cache_table mc WHERE mi.name=".$dbh->quote($movieName)." AND mc.filename=".$dbh->quote($filename). ";") || die "Prepare failed: $DBI::errstr at setResolutionDB()\n";
		$sth->execute() || die "Couldn't execute query: $DBI::errstr at setResolutionDB() when inserting.\n";
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr . " at setResolutionDB()"}
	} else {
		$sth=$dbh->prepare("UPDATE movie_files_table mf LEFT JOIN movie_info_table mi ON mf.movie_id = mi.id LEFT JOIN movie_cache_table mc ON mf.cache_id = mc.id SET mf.quality=".$dbh->quote($data)." WHERE (mf.movie_id=mi.id) AND mi.name=".$dbh->quote($movieName)." AND mc.filename=".$dbh->quote($filename). ";") || die "Prepare failed: $DBI::errstr at setResolutionDB()\n";
		$success &&= $sth->execute() || die "Couldn't execute query: $DBI::errstr at setResolutionDB() when updating.\n";
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr . " at setResolutionDB()"}
	}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect at setResolutionDB()\n";
}
sub setDurationDB {
	my $movieName = shift;
	my $data = shift;
	my $filename = shift;
	my @fileNameSplit = split('/', $filename);
	my $path = substr $filename, 0, (length($filename) - length($fileNameSplit[((scalar @fileNameSplit)-1)]));
	$filename = $fileNameSplit[((scalar @fileNameSplit)-1)];
	my ($dbh, $sth);
	$movieName = nameProcessor(lc($movieName));
	my $exists = checkFileMovieRelation($movieName, $filename);
	my $success = 1;
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr at setDurationDB()\n";	
	checkFileAndPathsInCacheTable($filename, $path);
	
	$exists = checkFileMovieRelation($movieName, $filename);
	if (!$exists) {
		$sth=$dbh->prepare("INSERT INTO movie_files_table(duration, movie_id, cache_id) SELECT ".$dbh->quote($data).", mi.id, mc.id FROM movie_info_table mi, movie_cache_table mc WHERE mi.name=".$dbh->quote($movieName)." AND mc.filename=".$dbh->quote($filename). ";") || die "Prepare failed: $DBI::errstr\n";
		$sth->execute() || die "Couldn't execute query: $DBI::errstr at setDurationDB()\n";
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	} else {
		$sth=$dbh->prepare("UPDATE movie_files_table mf LEFT JOIN movie_info_table mi ON mf.movie_id = mi.id LEFT JOIN movie_cache_table mc ON mf.cache_id = mc.id SET mf.duration=".$dbh->quote($data)." WHERE (mf.movie_id=mi.id) AND mi.name=".$dbh->quote($movieName)." AND mc.filename=".$dbh->quote($filename). ";") || die "Prepare failed: $DBI::errstr\n";
		$success &&= $sth->execute() || die "Couldn't execute query: $DBI::errstr at setDurationDB()\n";
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr . " setDurationDB()"}
	}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
}
sub setNoMoviesInEnv {
	my $noMoviesLocal = shift;
	my ($dbh, $sth);
	my $success = 1;
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";	
	my $exists = getTotalNoMoviesFromEnv();
	if (!$exists) {
		$sth=$dbh->prepare("INSERT INTO movie_env_table (noMovies, confset) VALUES (".$dbh->quote($noMoviesLocal).",".$dbh->quote($cid).");") || die "Prepare failed: $DBI::errstr\n";
		$success &&= $sth->execute() || die "Couldn't execute query: $DBI::errstr at setNoMoviesInEnv() when inserting.\n";
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr; }
	} else {
		$sth=$dbh->prepare("UPDATE movie_env_table SET noMovies=".$dbh->quote($noMoviesLocal)." WHERE confset=".$dbh->quote($cid).";") || die "Prepare failed: $DBI::errstr\n";
		$success &&= $sth->execute() || die "Couldn't execute query: $DBI::errstr at setNoMoviesInEnv() when updating.\n";
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr; }
	}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
}
sub setMovieListCache {
	my $movieContainer_r = shift;
	my @movieListTocache = @$movieContainer_r;
	my ($dbh, $sth);
	my $success = 1;
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr at setMovieListCache()\n";	
	foreach my $fullpath (@movieListTocache) {
		if(substr($fullpath, -3,3) ne "../" && substr($fullpath, -2,2) ne "./") {
			$sth=$dbh->prepare("INSERT INTO movie_cache_table (path, confset) VALUES (".$dbh->quote($fullpath . "/").", ".$dbh->quote($cid).");") || die "Prepare failed: $DBI::errstr at setMovieListCache()\n";
			$success &&= $sth->execute() || die "Couldn't execute query: $DBI::errstr at setMovieListCache()\n";
			my $result = ($success ? $dbh->commit : $dbh->rollback);
			unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr . " at setMovieListCache()"; }
		}
	} 
	$sth->finish() if(defined($sth));
	$dbh->disconnect || die "Failed to disconnect\n";
}
sub setDiskDifferenceToMovieCache {
	my $diskList_r = shift;
	my $movieContainer_r = buildMovieContainerFromCache();
	my @localDBMovieContainer = @$movieContainer_r;
	my $exists = 0;
	my ($dbh, $sth, $success);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr at setDiskDifferenceToMovieCache()\n";	
	#First we add movies to db cache if the have appeared new on disk since last time:
	foreach my $diskFilmDiskPath (@$diskList_r) {
		foreach my $dbFilmDiskPath (@localDBMovieContainer) {
			if($diskFilmDiskPath eq $dbFilmDiskPath) {
				$exists = 1	
			}
		}
		if(!$exists) {
			if(substr($diskFilmDiskPath, -3,3) ne "../" && substr($diskFilmDiskPath, -2,2) ne "./") {
				$success = 1;
				$sth=$dbh->prepare("INSERT INTO movie_cache_table (path, confset) VALUES (".$dbh->quote($diskFilmDiskPath . "/").", ".$dbh->quote($cid).");") || die "Prepare failed: $DBI::errstr at setDiskDifferenceToMovieCache()\n";
				$success &&= $sth->execute() || die "Couldn't execute query: $DBI::errstr at setDiskDifferenceToMovieCache() when trying to INSERT\n";
				my $result = ($success ? $dbh->commit : $dbh->rollback);
				unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr . " at setDiskDifferenceToMovieCache() when trying to INSERT"; } 
				$sth->finish();
			}
		}
		$exists = 0;
	}
	#Next we remove movies from db cache if they exist in cache but not on disk
	foreach my $dbFilmDiskPath (@localDBMovieContainer) {
		foreach my $diskFilmDiskPath (@$diskList_r) {
			if($diskFilmDiskPath eq $dbFilmDiskPath) {
				$exists = 1	
			}
		}
		if(!$exists) {
			$success = 1;
			$sth=$dbh->prepare("DELETE FROM movie_cache_table WHERE path=".$dbh->quote($dbFilmDiskPath . "/")." AND confset=".$dbh->quote($cid).";") || die "Prepare failed: $DBI::errstr at setDiskDifferenceToMovieCache()\n";
			$success &&= $sth->execute() || die "Couldn't execute query: $DBI::errstr at setDiskDifferenceToMovieCache() when trying to DELETE\n";
			my $result = ($success ? $dbh->commit : $dbh->rollback);
			unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr . " at setDiskDifferenceToMovieCache() when trying to DELETE\n"; } 
			$sth->finish();
		}
		$exists = 0;
	}
	$dbh->disconnect || die "Failed to disconnect at setDiskDifferenceToMovieCache()\n";
	setNoMoviesInEnv(scalar @localDBMovieContainer - 2);
}
sub addRating {
	my $movieName = shift;
	my $rating = shift;
	my ($dbh, $sth);
	chomp($rating);
	$movieName = nameProcessor(lc($movieName));
	my $existence = checkMovieExistence($movieName);
	my $success = 1;
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	if(!$existence) {
		$sth=$dbh->prepare("INSERT INTO movie_info_table (name, rating) VALUES (" . $dbh->quote($movieName) . "," . $dbh->quote($rating) .");") || die "Couldn't insert record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	} else {
		$sth=$dbh->prepare("UPDATE movie_info_table SET rating=". $dbh->quote($rating) ." WHERE name=". $dbh->quote($movieName) .";") || die "Couldn't update record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
}
sub addYear {
	my $movieName = shift;
	my $year = shift;
	my ($dbh, $sth);
	chomp($year);
	$movieName = nameProcessor(lc($movieName));
	my $existence = checkMovieExistence($movieName);
	my $success = 1;
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	if(!$existence) {
		$sth=$dbh->prepare("INSERT INTO movie_info_table (name, year) VALUES (" . $dbh->quote($movieName) . "," . $dbh->quote($year) .");") || die "Couldn't insert record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction at addYear(): " . $dbh->errstr }
	} else {
		$sth=$dbh->prepare("UPDATE movie_info_table SET year=". $dbh->quote($year) ." WHERE name=". $dbh->quote($movieName) .";") || die "Couldn't update record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction at addYear():: " . $dbh->errstr }
	}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
}
sub addMovie {
	#Adds movie name and corresponding cover url, or updates the url if the movie name exists.
	my $movieName = shift;
	my $imageLink = shift;
	my ($dbh, $sth);
	$movieName = nameProcessor(lc($movieName));
	my $existence = checkMovieExistence($movieName);
	my $success = 1;
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	if(!$existence) {
		$sth=$dbh->prepare("INSERT INTO movie_info_table (name, url) VALUES (" . $dbh->quote($movieName) . "," . $dbh->quote($imageLink) . ");") || die "Couldn't insert record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	} else {
		$sth=$dbh->prepare("UPDATE movie_info_table SET url=" . $dbh->quote($imageLink) . " WHERE name=" . $dbh->quote($movieName) . ";") || die "Couldn't update record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
	#checkAndGetMovieRatingInDB($movieName);
}
sub addSuggestions {
	my $movieName = shift;
	my $suggestions = shift;
	my ($dbh, $sth);
	$movieName = nameProcessor(lc($movieName));
	my $existence = checkMovieExistence($movieName);
	my $success = 1;
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	if(!$existence) {
		$sth=$dbh->prepare("INSERT INTO movie_info_table (name, tasteKidList) VALUES (" . $dbh->quote($movieName) . "," . $dbh->quote($suggestions) . ");") || die "Couldn't insert record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	} else {
		$sth=$dbh->prepare("UPDATE movie_info_table SET tasteKidList=" . $dbh->quote($suggestions) . " WHERE name=" . $dbh->quote($movieName) . ";") || die "Couldn't update record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
	#checkAndGetMovieRatingInDB($movieName);
}
sub addTrailerUrl {
	my $movieName = shift;
	my $trailerUrl = shift;
	my $embedable = shift;
	my ($dbh, $sth);
	if(!$trailerUrl) {return 0;}
	chomp($trailerUrl);
	$movieName = nameProcessor(lc($movieName));
	my $existence = checkMovieExistence($movieName);
	my $success = 1;
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	if(!$existence) {
		$sth=$dbh->prepare("INSERT INTO movie_info_table (name, trailerUrl, embedable) VALUES (" . $dbh->quote($movieName) . "," . $dbh->quote($trailerUrl) . ",". $dbh->quote($embedable) .");") || die "Couldn't insert record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	} else {
		$sth=$dbh->prepare("UPDATE movie_info_table SET trailerUrl=". $dbh->quote($trailerUrl) .", embedable=". $dbh->quote($embedable) ." WHERE name=". $dbh->quote($movieName) .";") || die "Couldn't update record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
}
sub addGenre {
	my $movieName = shift;
	my $genre = shift;
	my ($dbh, $sth);
	chomp($genre);
	$movieName = nameProcessor(lc($movieName));
	my $existence = checkMovieExistence($movieName);
	my $success = 1;
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	if(!$existence) {
		$sth=$dbh->prepare("INSERT INTO movie_info_table (name, genre) VALUES (" . $dbh->quote($movieName) . "," . $dbh->quote($genre) .");") || die "Couldn't insert record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	} else {
		$sth=$dbh->prepare("UPDATE movie_info_table SET genre=". $dbh->quote($genre) ." WHERE name=". $dbh->quote($movieName) .";") || die "Couldn't update record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
}
sub addIMDBUrl {
	my $movieName = shift;
	my $limdburl = shift;
	my ($dbh, $sth);
	chomp($limdburl);
	$movieName = nameProcessor(lc($movieName));
	my $existence = checkMovieExistence($movieName);
	my $success = 1;
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	if(!$existence) {
		$sth=$dbh->prepare("INSERT INTO movie_info_table (name, imdbUrl) VALUES (" . $dbh->quote($movieName) . "," . $dbh->quote($limdburl) .");") || die "Couldn't insert record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	} else {
		$sth=$dbh->prepare("UPDATE movie_info_table SET imdbUrl=". $dbh->quote($limdburl) ." WHERE name=". $dbh->quote($movieName) .";") || die "Couldn't update record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
	}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
}
sub addPlot {
	my $movieName = shift;
	my $plot = shift;
	my ($dbh, $sth);
	chomp($plot);
	$movieName = nameProcessor(lc($movieName));
	my $existence = checkMovieExistence($movieName);
	my $success = 1;
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	if(!$existence) {
		$sth=$dbh->prepare("INSERT INTO movie_info_table (name, plot) VALUES (" . $dbh->quote($movieName) . "," . $dbh->quote($plot) .");") || die "Couldn't insert record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction at addPlot(): " . $dbh->errstr }
	} else {
		$sth=$dbh->prepare("UPDATE movie_info_table SET plot=". $dbh->quote($plot) ." WHERE name=". $dbh->quote($movieName) .";") || die "Couldn't update record : $DBI::errstr";
		$success &&= $sth->execute();
		my $result = ($success ? $dbh->commit : $dbh->rollback);
        unless ($result) { die "Couldn't finish transaction at addPlot():: " . $dbh->errstr }
	}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
}
1;