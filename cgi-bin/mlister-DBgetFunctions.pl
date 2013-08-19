#!/usr/bin/perl -w
#Creator: Atle Holm - atle@team-holm.net
use strict;

my $dbUser = getDbUser();
my $dbPassword = getDbPassword();
my $urlMoviePlacement = getUrlMoviePlacement();
my $moviePlacement = getMoviePlacement();
my $urlImagePlacement = getUrlImagePlacement();
my $mainScriptName = getMainScriptName();
my $tableType =  getTableType();
my $configFile = getConfigFile();
my $numberOfRecomendations = getNumberOfRecomendations();
my $cgi = getCGIObj();
my $movieNameOffset = $ENV{'QUERY_STRING'} && defined(uri_unescape($cgi->param('qid'))) ? 0 : getMovieNameOffset();
my $linkRevisor = getLinkRevisor();
my $updateInterval = getUpdateInterval();
my $cid = getConfsetID($configFile);

sub getDBSuggestions {
	#Called from html/table script only
	my $movieName = shift;
	$movieName = substr $movieName, $movieNameOffset;
	$movieName = nameProcessor(lc($movieName));
	my ($dbh, $sth, $result, $resultReturn);

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$sth=$dbh->prepare("SELECT tasteKidList FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";") || die "Prepare failed: $DBI::errstr\n";
	$sth->execute() || die "Couldn't execute query: $DBI::errstr\n";
	my $suggestionCounter = 0;
	my $tempNumberOfRecomendations = $numberOfRecomendations;
	if($linkRevisor eq "-medium") {
		$numberOfRecomendations = 3;
	}
	while (($result) = $sth->fetchrow_array) {
		if($result) {$resultReturn = $result;}
		$suggestionCounter++;
		last if ($suggestionCounter == $numberOfRecomendations);
	}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect\n";
	
	if($resultReturn) { 
		my $returnString;
		my @split = split(" - ", $resultReturn);
		if(scalar (@split) > 1){
			my $suggestionCounter = 0;
			foreach(@split) {
				last if ($suggestionCounter == $numberOfRecomendations);
				chomp($returnString .= $cgi->a({-href=>'http://www.themoviedb.org/search?query=' .uri_escape(nameProcessor($_)), -class=>'suggestionLinks'.$linkRevisor, -target=>"_blank"}, $_));
				$returnString .= $cgi->br;
				$suggestionCounter++;
			}
		} else {
			if(lc($split[0]) eq "no suggestions found..") {
				$returnString = $cgi->a({-href=>'http://www.tastekid.com', -class=>'suggestionLinks'.$linkRevisor, -target=>"_blank"}, "No Suggestions Found...").$cgi->br;
			} else {
				chomp($returnString = $cgi->a({-href=>'http://www.themoviedb.org/search?query=' .uri_escape(nameProcessor($_)), -class=>'suggestionLinks'.$linkRevisor, -target=>"_blank"}, $split[0]));
				$returnString .= $cgi->br;
			}
		}
		$numberOfRecomendations = $tempNumberOfRecomendations;
		return $returnString;
	}
	else { $numberOfRecomendations = $tempNumberOfRecomendations; return $cgi->a({-href=>'http://www.tastekid.com', -class=>'suggestionLinks'.$linkRevisor, -target=>"_blank"}, "No suggestions found...").$cgi->br;}
}
sub getDBRawSuggestions {
	my $movieName = shift;
	#$movieName = nameProcessor(lc($movieName));
	my ($dbh, $sth, $result);
	my $resultReturn = "";
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$sth=$dbh->prepare("SELECT tasteKidList FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";") || die "Prepare failed: $DBI::errstr\n";
	$sth->execute() || die "Couldn't execute query at getDBRawSuggestions(): $DBI::errstr\n";
	my $suggestionCounter = 0;
	my $tempNumberOfRecomendations = $numberOfRecomendations;
	if($linkRevisor eq "-medium") {
		$numberOfRecomendations = 3;
	}
	while (($result) = $sth->fetchrow_array) {
		if($result) {$resultReturn = $result;}
		$suggestionCounter++;
		last if ($suggestionCounter == $numberOfRecomendations);
	}
	$sth->finish();
	$dbh->disconnect || die "Failed to disconnect at getDBRawSuggestions()\n";
	if (defined($resultReturn)) {return $resultReturn;}
	else {return "";}
}
sub getDBAllRepositories {
	my ($dbh, $result);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || return [0, "Error opening database at getDBAllRepositories(): $DBI::errstr\n"];
	$result=$dbh->selectall_arrayref("SELECT name, confset, state, comments FROM movie_repositories_table;") || return [0, "Prepare failed at getDBAllRepositories(): $DBI::errstr\n"];
	$dbh->disconnect || die "Failed to disconnect at getDBAllRepositories()\n";
	if(defined($result->[0]->[0])) {
		return [1, $result];
	} else { return [0, "No repositories found"]; }
}
sub getDBRepository {
	my $configurationSet = shift;
	my ($dbh, $result);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database at getDBRepository(): $DBI::errstr\n";
	$result=$dbh->selectall_arrayref("SELECT name, confset, state FROM movie_repositories_table WHERE confset=".$dbh->quote($configurationSet).";") || die "Prepare failed at getDBRepository(): $DBI::errstr\n";
	$dbh->disconnect || die "Failed to disconnect at getDBRepository()\n";
	if(defined($result->[0]->[0])) {
		return $result;
	} else { return 0; }
}
sub getDBIMDBUrl {
	#Called from html/table script only
	my $movieName_f = shift;
	my $movieName = substr $movieName_f, $movieNameOffset;
	$movieName = nameProcessor(lc($movieName));
	#Get rating from database:
	my ($dbh, $sth, $result);

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT imdbUrl FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	if(!$result) {
		initiateMovieInfo($movieName_f);
		$result = $dbh->selectall_arrayref("SELECT imdbUrl FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	}
	$result = $result->[0]->[0];
	$dbh->disconnect || die "Failed to disconnect\n";
	if($result) { return $result;}
	else { return "N/A";}
}
sub getDBMovieRating {
	#Called from html/table script only
	my $movieName_f = shift;
	my $movieName = substr $movieName_f, $movieNameOffset;
	$movieName = nameProcessor(lc($movieName));
	#Get rating from database:
	my ($dbh, $sth, $result);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT rating FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	if(!$result) {
		initiateMovieInfo($movieName_f);
		$result = $dbh->selectall_arrayref("SELECT rating FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	}
	$result = $result->[0]->[0];
	$dbh->disconnect || die "Failed to disconnect\n";
	if($result) { return $result;}
	else { return "N/A";}
}
sub getDBMovieCover {
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	#Get movieCover from database:
	my ($dbh, $sth, $result);

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT url FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	$result = $result->[0]->[0];
	$dbh->disconnect || die "Failed to disconnect\n";
	if($result) { return $result;}
	else { return "N/A";}
}
sub checkAndGetMovieRatingInDB {
	#Checks if rating is in DB
	#If there has been $updateInterval time since last update on rating, then update
	#If rating is 0 in DB, then update
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	#my $movedURL = shift;
	my ($dbh, $sth, $result, $timediff);

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	if(!checkMovieInfoSearched($movieName)) {
		$result = $dbh->selectall_arrayref("SELECT rating FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
		$result = $result->[0]->[0];
	} else {
		$result = 1;
	}
	$timediff = $dbh->selectall_arrayref("SELECT datediff(now(),updated_at) FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	$timediff = $timediff->[0]->[0];
	my @lt = localtime(time);
	if(defined($timediff) && defined($updateInterval)) {
		if(($timediff  > $updateInterval) || !defined($result) || $result eq "" || !$result) { 
			#((str2time(strftime("%c\n", @lt))) - str2time($resultDate))
			# was replaced by:
			#SELECT datediff(now(),updated_at) FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";
			#print "Failed time interval check at checkAndGetMovieRatingInDB() for " . $movieName . " with tdiff ".$timediff." and ui ".$updateInterval.", result was ".$result."<br/>";
		
			#1. Find rating from API:
			my $rating = getRatingFromAPI($movieName);
			#2. Store rating in database if it is valid:
			if(!$rating) { 
				$dbh->disconnect || die "Failed to disconnect\n";
				return 0; 		
			} else {
				my $success = 1;
				$sth=$dbh->prepare("UPDATE movie_info_table SET rating=". $dbh->quote($rating) ." WHERE name=". $dbh->quote($movieName) .";") || die "Prepare failed: $DBI::errstr\n";
				$success &&= $sth->execute() || die "Couldn't execute query: $DBI::errstr\n";
				my $result = ($success ? $dbh->commit : $dbh->rollback);
				#print "We update with ".$rating." for ".$movieName." with success: ".$success."<br/><br/>";
				unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
				$sth->finish();
			}
		}
	}
	#3. Return true if all is ok
	$dbh->disconnect || die "Failed to disconnect\n";
	return 1;
}
sub checkTasteKidList {
	#Checks if $movieName has a tasteKidList
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my ($dbh, $result);

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT tasteKidList FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	$result = $result->[0]->[0];
	$dbh->disconnect || die "Failed to disconnect\n";
	if(defined($result)) {
		if(length($result) > 1) { return 1; }
		else { return 0; }
	} else { return 0; }
}
sub checkDBConnection {
	my $dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || (print STDERR "Database connection does no exist\n" && return 0);
	$dbh->disconnect || die "print STDERR Failed to disconnect from database\n";
	return 1;
}
sub checkMovieExistence {
	#Checks if $movieName exists in DB
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my ($dbh, $result);
	
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT name FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	$result = $result->[0]->[0];
	$dbh->disconnect || die "Failed to disconnect\n";
	
	if(defined($result)) { return 1 if(length($result) > 1);}
	return 0;
}
sub checkMovieInfoSearched {
	#Checks if the movie is already Googled already for
	#Also checks if the movies time interval has passed, meaning its information needs to be updated again
	my $movieName = shift;
	my ($dbh, $result);
	#print "Checking if movie is searched for: ".$movieName."<br/>";
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT searched FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	#print "   - We got: ".$result->[0]->[0]."<br/>";
	$result = $result->[0]->[0];
	$dbh->disconnect || die "Failed to disconnect\n";	
	
	if(defined($result)) { return 1 if($result);}
	return 0;
}
sub checkMovieFileSearched {
	#Checks if movie is googled already for movie info
	my $filename = shift;
	my @fileNameSplit = split('/', $filename);
	$filename = $fileNameSplit[((scalar @fileNameSplit)-1)];
	my ($dbh, $result);
	
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT mf.searched FROM movie_files_table mf LEFT JOIN movie_cache_table mc ON mf.cache_id=mc.id WHERE mc.filename=". $dbh->quote($filename) .";");
	$result = $result->[0]->[0];
	$dbh->disconnect || die "Failed to disconnect\n";

	if(defined($result)) { return 1 if($result);}
	return 0;
}
sub checkCoverExistence {
	#Checks if $movieName exists in DB
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my ($dbh, $result);

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT url FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	$result = $result->[0]->[0];

	$dbh->disconnect || die "Failed to disconnect\n";
	if(defined($result)) { return 1 if(length($result) > 1);}
	return 0;
}
sub checkGenreExistence {
	#Checks if $movieName exists has genre set
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my ($dbh, $result);

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT genre FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	$result = $result->[0]->[0];
	
	$dbh->disconnect || die "Failed to disconnect\n";
	if(defined($result)) { return 1 if(length($result) > 1);}
	return 0;
}
sub checkPlotExistence {
	#Checks if $movieName exists has genre set
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my ($dbh, $result);

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT plot FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	$result = $result->[0]->[0];
	
	$dbh->disconnect || die "Failed to disconnect\n";
	if(defined($result)) { return 1 if(length($result) > 1);}
	return 0;
}
sub checkUrlExistence {
	#Checks if cover url exists in DB
	#Returns it if it exists
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my ($dbh, $result);

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT url FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	$result = $result->[0]->[0];
	
	$dbh->disconnect || die "Failed to disconnect\n";
	if(!$result) { return 0; }
	if($result ne "NONE-ADDED") { return $result; }
	else { return 0; }
}
sub checkIMDBUrlExistence {
	#Checks if IMDBurl exists in DB
	#Returns it if it exists
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my ($dbh, $result);

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT IMDBUrl FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	$result = $result->[0]->[0];
	
	$dbh->disconnect || die "Failed to disconnect\n";
	if(!$result) { return 0; }
	if($result ne "NONE-ADDED") { return $result; }
	else { return 0; }
}
sub checkYearExistence {
	#Checks if IMDBurl exists in DB
	#Returns it if it exists
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my ($dbh, $result);

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT year FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	$result = $result->[0]->[0];
	
	$dbh->disconnect || die "Failed to disconnect\n";
	if(!$result) { return 0; }
	if(defined($result)) { return $result; }
	else { return 0; }
}
sub checkTrailerExistence {
	#Checks if trailer exists in DB
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my ($dbh, $resul);
	my $result = "NONE-ADDED";

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT trailerUrl FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	$result = $result->[0]->[0];
	
	$dbh->disconnect || die "Failed to disconnect\n";
	if($result ne "NONE-ADDED") { return 1; }
	else { return 0; }
}
sub checkBitRateIsDBSet {
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my $filename = shift;
	my @fileNameSplit = split('/', $filename);
	$filename = $fileNameSplit[((scalar @fileNameSplit)-1)];
	my ($dbh, $result);

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT mf.bitrate FROM movie_info_table mi JOIN movie_files_table mf ON (mi.id=mf.movie_id) JOIN movie_cache_table mc ON (mf.cache_id=mc.id) WHERE mi.name=".$dbh->quote($movieName)." AND mc.filename=".$dbh->quote($movieName).";");
	$result = $result->[0]->[0];
	$dbh->disconnect || die "Failed to disconnect at checkBitRateIsDBSet()\n";
	if(defined($result)) {
		if(length($result)) { return 1; }
		else { return 0; }
	} else { return 0; }
}
sub checkFileAndPathsInCacheTable {
	my $filename = shift;
	my $path = shift;
	my $success = 1;
	my ($dbh, $sth);
	my $filepathcacheHasNull = checkPathForNULLInCache($path);
	my $thisRowExists = checkPathForFileInCache($filename, $path);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	if($filepathcacheHasNull) {
		$sth=$dbh->prepare("UPDATE movie_cache_table mc SET mc.filename=".$dbh->quote($filename)." WHERE mc.path=".$dbh->quote($path)." AND mc.confset=".$dbh->quote($cid)." AND mc.filename IS NULL;") || die "Prepare failed: $DBI::errstr\n";
		$sth->execute() || die "Couldn't execute query: $DBI::errstr at checkFileAndPathsInCacheTable()\n";
		my $result = ($success ? $dbh->commit : $dbh->rollback);
		unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
		$sth->finish();
	} elsif(!$thisRowExists) {
		if(substr($path, -3,3) ne "../" && substr($path, -2,2) ne "./") {
			$sth=$dbh->prepare("INSERT INTO movie_cache_table(filename, path, confset) VALUES(".$dbh->quote($filename).", ".$dbh->quote($path).", ".$dbh->quote($cid).");") || die "Prepare failed: $DBI::errstr\n";
			$sth->execute() || die "Couldn't execute query: $DBI::errstr at checkFileAndPathsInCacheTable()\n";
			my $result = ($success ? $dbh->commit : $dbh->rollback);
			unless ($result) { die "Couldn't finish transaction: " . $dbh->errstr }
			$sth->finish();
		}
	} 
	$dbh->disconnect || die "Failed to disconnect\n";
}
sub checkFileMovieRelation {
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my $filename = shift;
	my ($dbh, $sth, $exists);
	
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$exists = $dbh->selectall_arrayref("SELECT mf.id FROM movie_info_table mi LEFT JOIN movie_files_table mf ON mi.id=mf.movie_id LEFT JOIN movie_cache_table mc ON mf.cache_id = mc.id WHERE mi.name=".$dbh->quote($movieName)." AND mc.filename=".$dbh->quote($filename).";");
	$exists = $exists->[0]->[0];
	$dbh->disconnect || die "Failed to disconnect at checkFileMovieRelation()\n";
	if(defined($exists) && length($exists) > 0) { return $exists; }
	else { return 0; }
}
sub checkPathForNULLInCache {
	my $filepath = shift;
	my ($dbh, $sth, $exists);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$exists = $dbh->selectall_arrayref("SELECT id FROM movie_cache_table WHERE filename IS NULL AND path=".$dbh->quote($filepath)." AND confset=".$dbh->quote($cid).";");
	$exists = $exists->[0]->[0];

	$dbh->disconnect || die "Failed to disconnect at checkPathForNULLInCache()\n";
	if(defined($exists)) {
		if(length($exists) > 0) { return 1; }
		else { return 0; }
	} else { return 0; }
}
sub checkPathForFileInCache {
	my $filename = shift;
	my $filepath = shift;
	my ($dbh, $sth, $exists);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr at checkPathForFileInCache()\n";
	$exists = $dbh->selectall_arrayref("SELECT filename FROM movie_cache_table WHERE filename=".$dbh->quote($filename)." AND path=".$dbh->quote($filepath)." AND confset=".$dbh->quote($cid).";");
	$exists = $exists->[0]->[0];

	$dbh->disconnect || die "Failed to disconnect at checkPathForFileInCache()\n";
	if(defined($exists)) {
		if(length($exists) > 0) { return 1; }
		else { return 0; }
	} else { return 0; }
}
sub getBitRateDB {
	#Called from html/table script only
	my $movieName = shift;
	$movieName = substr $movieName, $movieNameOffset;
	$movieName = nameProcessor(lc($movieName));
	my $filename = shift;
	my @fileNameSplit = split('/', $filename);
	$filename = $fileNameSplit[((scalar @fileNameSplit)-1)];
	my ($dbh, $result);
	
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT mf.bitrate FROM movie_info_table mi LEFT JOIN movie_files_table mf ON mi.id=mf.movie_id LEFT JOIN movie_cache_table mc ON mf.cache_id=mc.id WHERE mi.name=".$dbh->quote($movieName)." AND mc.filename=".$dbh->quote($filename).";");
	$result = $result->[0]->[0];

	$dbh->disconnect || die "Failed to disconnect at getBitRateDB()\n";
	if(defined($result)) {
		if(length($result) > 1) { return $result; }
		else { return 0; }
	} else { return 0; }
}
sub getMovieIDByMovieName {
	#Called from html/table script only
	my ($dbh, $result);
	my $movieName = shift;
	$movieName = substr $movieName, $movieNameOffset;
	$movieName = nameProcessor(lc($movieName));
	#print "Trying to fetch " . $movieName . "<br/>";
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr at getMovieIDByMovieName()\n";
	$result = $dbh->selectall_arrayref("SELECT id FROM movie_info_table WHERE name=".$dbh->quote($movieName).";");
	$result = $result->[0]->[0];

	$dbh->disconnect || die "Failed to disconnect at getMovieIDByMovieName()\n";
	if(defined($result)) {
		if(length($result) > 0) { return $result; }
		else { return 0; }
	} else { return 0; }	
}
sub getMovieNameByID {
	my ($dbh, $movieName);
	my $movieID = shift;

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr at getMovieNameByID()\n";
	$movieName = $dbh->selectall_arrayref("SELECT name FROM movie_info_table WHERE id=".$dbh->quote($movieID).";");
	$movieName = $movieName->[0]->[0];

	$dbh->disconnect || die "Failed to disconnect at getMovieNameByID()\n";
	if(defined($movieName)) {
		if(length($movieName) > 0) { return $movieName; }
		else { return 0; }
	} else { return 0; }	
}
sub checkPathForFilesInCache {
	my $filepath = shift;
	my ($dbh, $sth, $rows);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n at checkPathForFilesInCache()";
	$rows = $dbh->selectall_arrayref("SELECT filename FROM movie_cache_table WHERE path=".$dbh->quote($filepath."/")." AND confset=".$dbh->quote($cid).";");
	foreach my $row (@$rows) {
		if ($row->[0]) {
			$dbh->disconnect || die "Failed to disconnect at checkPathForFilesInCache()\n"; 
			return 1;
		}
	}
	$dbh->disconnect || die "Failed to disconnect at checkPathForFilesInCache()\n";
	return 0;
}
sub checkDurationIsDBSet {
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my $filename = shift;
	my @fileNameSplit = split('/', $filename);
	$filename = $fileNameSplit[((scalar @fileNameSplit)-1)];
	my ($dbh, $result);

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr at checkDurationIsDBSet()\n";
	$result = $dbh->selectall_arrayref("SELECT mf.duration FROM movie_info_table mi LEFT JOIN movie_files_table mf ON mi.id=mf.movie_id LEFT JOIN movie_cache_table mc ON mf.cache_id = mc.id WHERE mi.name=".$dbh->quote($movieName)." AND mc.filename=".$dbh->quote($movieName).";");
	$result = $result->[0]->[0];
	$dbh->disconnect || die "Failed to disconnect at checkDurationIsDBSet()\n";
	if(defined($result)) {
		if(length($result) > 1) { return $result; }
		else { return 0; }
	} else { return 0; }
}
sub checkResolutionIsDBSet {
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my $filename = shift;
	my @fileNameSplit = split('/', $filename);
	$filename = $fileNameSplit[((scalar @fileNameSplit)-1)];
	my ($dbh, $result);

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr at checkResolutionIsDBSet()\n";
	$result = $dbh->selectall_arrayref("SELECT mf.quality FROM movie_info_table mi LEFT JOIN movie_files_table mf ON mi.id=mf.movie_id LEFT JOIN movie_cache_table mc ON mf.cache_id = mc.id WHERE mi.name=".$dbh->quote($movieName)." AND mc.filename=".$dbh->quote($movieName).";");
	$result = $result->[0]->[0];
	$dbh->disconnect || die "Failed to disconnect at checkResolutionIsDBSet()\n";
	if(defined($result)) {
		if(length($result) > 1) { return $result; }
		else { return 0; }
	} else { return 0; }
}
sub getDBPlotByID {
	my $plotID = shift;
	my ($dbh, $result);
	
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database at getDBPlotByID(): $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT plot FROM movie_info_table WHERE id=".$dbh->quote($plotID).";");
	$result = $result->[0]->[0];

	$dbh->disconnect || die "Failed to disconnect at getDBPlotByID()\n";
	if(defined($result)) {
		if(length($result) >= 1) { return $result; }
		else { return 0; }
	} else { return 0; }
}
sub getDBProductionYearByID {
	my $plotID = shift;
	my ($dbh, $result);
	
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database at getDBPlotByID(): $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT year FROM movie_info_table WHERE id=".$dbh->quote($plotID).";");
	$result = $result->[0]->[0];

	$dbh->disconnect || die "Failed to disconnect at getDBPlotByID()\n";
	if(defined($result)) {
		if(length($result) >= 1) { return $result; }
		else { return 0; }
	} else { return 0; }
}
sub getVideoContentDB {
	my $videoContent_r = shift;
	my $path = shift;
	my $dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr at getVideoContentDB()\n";
	my $rows = $dbh->selectall_arrayref("SELECT filename FROM movie_cache_table WHERE path=".$dbh->quote($path."/")." AND confset=".$dbh->quote($cid).";");
	foreach my $row (@$rows) {
		push(@$videoContent_r, $row->[0]);
	}
	$dbh->disconnect || die "Failed to disconnect at getVideoContentDB()\n";
}
sub getTotalNoMoviesFromEnv {
	#Gets total number of movies found to be available via a specific config file:
	my ($dbh, $result);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT noMovies FROM movie_env_table WHERE confset=".$dbh->quote($cid).";");
	$result = $result->[0]->[0];
	$dbh->disconnect || die "Failed to disconnect at getTotalNoMoviesFromEnv()\n";
	if(defined($result)) { return $result; }
	else { return 0;}
}
sub getDBMovieListCount {
	#Gets the number of movies that has been fulle scanned to database:
	my ($dbh, $result);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT COUNT(DISTINCT mi.id) FROM movie_info_table mi LEFT JOIN movie_files_table mf ON mi.name=mf.movie_name LEFT JOIN movie_cache_table mc ON mf.cache_id = mc.id WHERE mc.confset=".$dbh->quote($cid).";");
	$result = $result->[0]->[0];
	$dbh->disconnect || die "Failed to disconnect\n";
	return $result;
}
sub getDurationDB {
	#Called from html/table script only
	my $movieName = shift;
	$movieName = substr $movieName, $movieNameOffset;
	$movieName = nameProcessor(lc($movieName));
	my $filename = shift;
	my @fileNameSplit = split('/', $filename);
	$filename = $fileNameSplit[((scalar @fileNameSplit)-1)];
	my ($dbh, $result);
	
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr at getDurationDB()\n";
	$result = $dbh->selectall_arrayref("SELECT mf.duration FROM movie_info_table mi LEFT JOIN movie_files_table mf ON mi.id=mf.movie_id LEFT JOIN movie_cache_table mc ON mf.cache_id = mc.id WHERE mi.name=".$dbh->quote($movieName)." AND mc.filename=".$dbh->quote($filename).";");
	$result = $result->[0]->[0];
	$dbh->disconnect || die "Failed to disconnect at getDurationDB()\n";
	if(defined($result)) {
		if(length($result) > 1) { return $result; }
		else { return 0; }
	} else { return 0; }
}
sub getNextMovieFromDB {
	my $movieName = shift;
	return 0 if(intCheck($movieName) && $movieName == 0);
	$movieName = $movieName;
	my ($dbh, $result, $id);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr at getDurationDB()\n";
	$result = $dbh->selectall_arrayref("SELECT mi.id FROM movie_info_table mi JOIN movie_files_table mf ON mi.id=mf.movie_id JOIN movie_cache_table mc ON mf.cache_id = mc.id WHERE mi.name>".$dbh->quote($movieName)." AND mc.confset=".$dbh->quote($cid)." ORDER BY mi.name LIMIT 0,1;");
	$id = $result->[0]->[0];
	#print $id."<br/>";
	if(defined($id)) {
		$result = $dbh->selectall_arrayref("SELECT mi.name, mc.path, mc.filename FROM movie_info_table mi LEFT JOIN movie_files_table mf ON mi.id=mf.movie_id LEFT JOIN movie_cache_table mc ON mf.cache_id = mc.id WHERE mi.id=".$id.";");
	} else {
		$dbh->disconnect || die "Failed to disconnect at getNextMovieFromDB()\n";
		return 0;
	}
	$dbh->disconnect || die "Failed to disconnect at getNextMovieFromDB()\n";
	#print $result->[0]->[0];
	if(defined($result->[0]->[0])) {
		return $result;
	} else { return 0; }
}
sub getResolutionDB {
	#Called from html/table script only
	my $movieName = shift;
	$movieName = substr $movieName, $movieNameOffset;
	$movieName = nameProcessor(lc($movieName));
	my $filename = shift;
	my @fileNameSplit = split('/', $filename);
	$filename = $fileNameSplit[((scalar @fileNameSplit)-1)];
	my ($dbh, $result);
	
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr at getResolutionDB()\n";
	$result = $dbh->selectall_arrayref("SELECT mf.quality FROM movie_info_table mi LEFT JOIN movie_files_table mf ON mi.id=mf.movie_id LEFT JOIN movie_cache_table mc ON mf.cache_id = mc.id WHERE mi.name=".$dbh->quote($movieName)." AND mc.filename=".$dbh->quote($filename).";");
	$result = $result->[0]->[0];

	$dbh->disconnect || die "Failed to disconnect at getResolutionDB()\n";
	if(defined($result)) {
		if(length($result) > 1) { return $result; }
		else { return 0; }
	} else { return 0; }
}
sub getDBMovieGenre {
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	$movieName = substr $movieName, $movieNameOffset;
	my ($dbh, $result);

	if (checkGenreExistence($movieName)) {
		$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
		$result = $dbh->selectall_arrayref("SELECT genre FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
		$result = $result->[0]->[0];
		$dbh->disconnect || die "Failed to disconnect\n";
		return $result;
	} else {
		return "N/A";
	}
}
sub getDBTrailerUrl {
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my ($dbh, $result);
	my $resultEmbedable = 0;

	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$result = $dbh->selectall_arrayref("SELECT trailerUrl FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	$result = $result->[0]->[0];
	
	$resultEmbedable = $dbh->selectall_arrayref("SELECT embedable FROM movie_info_table WHERE name=". $dbh->quote($movieName) .";");
	$resultEmbedable = $resultEmbedable->[0]->[0];
	
	$dbh->disconnect || die "Failed to disconnect\n";
	return ($result, $resultEmbedable);
}
sub buildMovieContainerFromCache {
	my @dbMovieContainer;
	my ($dbh, $dbMovieList);
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
	$dbMovieList = $dbh->selectall_arrayref("SELECT path FROM movie_cache_table WHERE confset=".$dbh->quote($cid)." GROUP BY path;");
	foreach (@$dbMovieList) {
		chop($_->[0]);
		push(@dbMovieContainer, $_->[0]);
	}
	$dbh->disconnect || die "Failed to disconnect\n";
	return \@dbMovieContainer;
}
sub getConfsetID {
	my $confset = shift;
	my ($dbh, $result);
	
	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr at getConfsetID()\n";
	$result = $dbh->selectall_arrayref("SELECT id FROM movie_repositories_table WHERE confset=".$dbh->quote($confset).";");
	$result = $result->[0]->[0];

	$dbh->disconnect || die "Failed to disconnect at getConfsetID()\n";
	if(defined($result)) {
		if(length($result) > 0) { return $result; }
		else { return -1; }
	} else { return -1; }
}
1;