#!/usr/bin/perl -w
#Creator: Atle Holm - atle@team-holm.net
use DBI;
use CGI;
use CGI::Pretty;
use CGI::Carp qw/fatalsToBrowser warningsToBrowser/;
use POSIX qw/ceil/;
use Fcntl qw(:seek);
use strict;
use IPC::Open3;
use WWW::Curl::Easy;
use File::Temp qw/tempfile/;
use File::Copy;
use ConfigReader::Simple;
use URI::Escape;
use LWP::Simple;
use Date::Parse;
use Date::Format;
use XML::Mini::Document;
use XML::Writer;
use JSON;
#use HTML::Entities; #temporary - for encode_entities()
#use Data::Dumper; #temporary - for Dumper($hash)
my $cgi=new CGI;
my $configFile;
if(defined &initiateConfigFile) {
	$configFile = initiateConfigFile();
} else {
	$configFile = "/usr/share/movieLister/setup/master-config.conf";
}
my $configSetup = ConfigReader::Simple->new($configFile); #This sets the configuration file for the script

#Configuration section, this sextions sets the defaults if they are not defined in the configuration file:
my $moviePlacement = "/usr/share/movieLister/symlinks/NFS1/";
my $urlMoviePlacement = "movieLister/symlinks/NFS1/";
my $urlImagePlacement = "movieLister/images/";
my $coverCachePlacement = "movieLister/coverCache/";
#my $webRoot = $ENV{DOCUMENT_ROOT};
my $webRoot = "/usr/share/";
my $listHeading = "Default Text Title";
my $dbUser = "root";
my $dbPassword = "pass";
my $currentPagePosition = 0;
my $currentMoviesPerPage = 14; #14 means 15 in this part of the script, 14 means 14 from the config file. See below.
my $styleSheetPlacement = "movieLister/css/";
my $movieNameOffset = 0; #Set to 0 if the moviename starts at the first character in the folder name
my $updateInterval = 7; #7 days
my $tableType = "medium"; #Size of table displaying the movies
my $javaScriptPlacement = "movieLister/js/";
my $sambaUsage = "off";
my $numberOfRecomendations = 4;
my $numberOfMoviesBeforeDBTakeOver = 20;
my $rowFactor = 1;
my $linkRevisor = "";
my $youtubeEmbedString = "\"allow_embed\": 1";
my $tastekidString = "\<meta name=\"keywords\" content=\"";
my $neverEmbed = 0;
my $tasteKidF = "";
my $tasteKidK = "";
my $forcedTasteKidAPI = 0;
my @thisScriptNameSplit = split('/', $0);
my $thisScriptName = $thisScriptNameSplit[((scalar @thisScriptNameSplit)-1)];

#If the values exist in the config file, use them:
if($configSetup->get("moviePlacement")) { $moviePlacement = $configSetup->get("moviePlacement"); }
if($configSetup->get("urlMoviePlacement")) { $urlMoviePlacement = $configSetup->get("urlMoviePlacement"); }
if($configSetup->get("urlImagePlacement")) { $urlImagePlacement = $configSetup->get("urlImagePlacement"); }
if($configSetup->get("coverCachePlacement")) { $coverCachePlacement = $configSetup->get("coverCachePlacement"); }
if($configSetup->get("listHeading")) { $listHeading = $configSetup->get("listHeading"); }
if($configSetup->get("dbUser")) { $dbUser = $configSetup->get("dbUser"); }
if($configSetup->get("dbPassword")) { $dbPassword = $configSetup->get("dbPassword"); }
if($configSetup->get("styleSheetPlacement")) { $styleSheetPlacement = $configSetup->get("styleSheetPlacement"); }
if($configSetup->get("tableType")) { $tableType = $configSetup->get("tableType"); }
if($configSetup->get("currentPagePosition") && intCheck($configSetup->get("currentMoviesPerPage"))) { $currentPagePosition = $configSetup->get("currentPagePosition"); }
if($configSetup->get("movieNameOffset") && intCheck($configSetup->get("currentMoviesPerPage"))) { $movieNameOffset = $configSetup->get("movieNameOffset"); }
if($configSetup->get("updateInterval") && intCheck($configSetup->get("currentMoviesPerPage"))) { $updateInterval = $configSetup->get("updateInterval"); }
if($configSetup->get("currentMoviesPerPage") && intCheck($configSetup->get("currentMoviesPerPage"))) { 
	$currentMoviesPerPage = $configSetup->get("currentMoviesPerPage");
	$currentMoviesPerPage = ($currentMoviesPerPage - 1);
	if($currentMoviesPerPage < 0) { $currentMoviesPerPage = 0;} #means 1
}
if($configSetup->get("javaScriptPlacement")) { $javaScriptPlacement = $configSetup->get("javaScriptPlacement"); }
if($configSetup->get("sambaUsage")) { $sambaUsage = $configSetup->get("sambaUsage"); }
if($configSetup->get("numberOfRecomendations")) { $numberOfRecomendations = $configSetup->get("numberOfRecomendations"); }
if($configSetup->get("numberOfMoviesBeforeDBTakeOver")) { $numberOfMoviesBeforeDBTakeOver = $configSetup->get("numberOfMoviesBeforeDBTakeOver"); }
if($configSetup->get("youtubeEmbedString")) { $youtubeEmbedString = $configSetup->get("youtubeEmbedString"); }
if($configSetup->get("tastekidString")) { $tastekidString = $configSetup->get("tastekidString"); }
if($configSetup->get("neverEmbed")) { $neverEmbed = $configSetup->get("neverEmbed"); }
if($configSetup->get("tasteKidF")) { $tasteKidF = $configSetup->get("tasteKidF"); }
if($configSetup->get("tasteKidK")) { $tasteKidK = $configSetup->get("tasteKidK"); }
if($configSetup->get("forcedTasteKidAPI")) { $forcedTasteKidAPI = $configSetup->get("forcedTasteKidAPI"); }

#If the variable has content we force it to end with a slash /
if($styleSheetPlacement) { $styleSheetPlacement = checkTrailingSlash($styleSheetPlacement);}
if($moviePlacement) { $moviePlacement = checkTrailingSlash($moviePlacement);}
if($urlMoviePlacement) { $urlMoviePlacement = checkTrailingSlash($urlMoviePlacement);}
if($urlImagePlacement) { $urlImagePlacement = checkTrailingSlash($urlImagePlacement);}
if($coverCachePlacement) { $coverCachePlacement = checkTrailingSlash($coverCachePlacement);}
if($webRoot) { $webRoot = checkTrailingSlash($webRoot);}
if($javaScriptPlacement) { $javaScriptPlacement = checkTrailingSlash($javaScriptPlacement);}
if(lc($sambaUsage) ne "on" && lc($sambaUsage) ne "off") {$sambaUsage = "off";}
if(!intCheck($numberOfRecomendations)) { $numberOfRecomendations = 4;}
if($numberOfRecomendations > 10) { $numberOfRecomendations = 10;}
if($ENV{'QUERY_STRING'}) { 
	$tableType = $cgi->param('pageSize') if(defined($cgi->param('pageSize'))); 
	if(defined(uri_unescape($cgi->param('getMovieAfter')))) { #This variable needs to be adjusted before loading of the files below so that the change will affect the code there as well.
		$movieNameOffset = 0; #Movie names fed in with getMovieAfter are always with no offset = no text in front of the movie name
	}
}
if ($tableType eq "big") {
	require "./mlister-bigTable.pl";
	$rowFactor = 1;
	$linkRevisor = "";
} elsif ($tableType eq "medium") {
	require "./mlister-mediumTable.pl";
	$rowFactor = 0.6;
	$linkRevisor = "-medium";
} elsif ($tableType eq "small") {
	require "./mlister-smallTable.pl";
	$rowFactor = 0.4;
	$linkRevisor = "-small";
} else {
	require "./mlister-mediumTable.pl";
	$rowFactor = 0.6;
	$linkRevisor = "-medium";
}
require "./mlister-nameProcessor.pl";
require "./mlister-xmlFunctions.pl";
if(!uri_unescape($cgi->param('getMainConfigset')) &&  !uri_unescape($cgi->param('validateMainConfiguration')) && lc(uri_unescape($cgi->param('setRepository') || "")) ne lc("/usr/share/movieLister/setup/master-config.conf")) {
	require "./mlister-DBgetFunctions.pl";
	require "./mlister-DBsetFunctions.pl";
}

#--> Start of area for url query parsing.
#The following if section checks for incomming parameters..
if($ENV{'QUERY_STRING'}) {
	my $forcedReload = uri_unescape($cgi->param('forceReload'));
	if(defined($forcedReload)) {
		setMovieInfoSearched(getMovieNameByID($forcedReload), 0) if(intCheck($forcedReload));
	}
	my $qid = uri_unescape($cgi->param('qid'));
	if(defined($qid)) {
		$movieNameOffset = 0;
		my $movieName = getMovieNameByID($qid);
		my $infoArray_r;
		if(!checkMovieInfoSearched($movieName)) { $infoArray_r = getMovieInfo($movieName); }
		else {$infoArray_r = createInfoArrayFromDB($movieName);}
		my @infoArray = @$infoArray_r;
		
		my $year = $infoArray[5];
		my $dbYear = getDBProductionYearByID($movieName);
		if (defined($year) && $year ne "" && $year ne $dbYear) { addYear($movieName, $year); }
		else {$year = $dbYear;}
		
		my $plot = $infoArray[4];
		my $dbPlot = getDBPlotByID($movieName);
		if (defined($plot) && $plot ne "" && $plot ne $dbPlot) { addPlot($movieName, $plot); }
		else {$plot = $dbPlot;}
		
		my $imdbUrl = $infoArray[3];
		my $dbImdbUrl = getDBIMDBUrl($movieName);
		if (defined($imdbUrl) && $imdbUrl ne "" && $imdbUrl ne $dbImdbUrl) { addIMDBUrl($movieName, $imdbUrl); }
		else {$imdbUrl = $dbImdbUrl;}
		
		my $movieRating = $infoArray[2];
		my $dbMovierating = getDBMovieRating($movieName);
		if (defined($movieRating) && $movieRating ne "" && $movieRating ne $dbMovierating) { addRating($movieName, $movieRating); }
		else {$movieRating = $dbMovierating;}
		
		my $movieGenre = $infoArray[1];
		my $dbMovieGenre = getDBMovieGenre($movieName);
		if (defined($movieGenre) && $movieGenre ne "" && $movieGenre ne $dbMovieGenre) { addGenre($movieName,$movieGenre); }
		else { $movieGenre = $dbMovieGenre;}
		
		my $movieCover = $infoArray[0];
		my $dbMovieCover = getDBMovieCover($movieName);
		if (defined($movieCover) && $movieCover ne "" && $movieCover ne $dbMovieCover) { addMovie($movieName,$movieCover); }
		else { $movieCover = $dbMovieCover; }
		
		#Acquire information and return xml according to table size.
		if ($tableType eq "big" || $tableType eq "medium") {
			##bigtable: *ratingContainer, *genreContainer, bitrateContainer, qualityContainer, durationContainer, *suggestionContainer, *coverContainer, *trailerContainer, *coverCell, trailerCell
			##mediumTable: *ratingContainer, *genreContainer, bitrateContainer, qualityContainer, durationContainer, *suggestionContainer, *coverContainer, *trailerContainer, *coverCell, trailerCell	
			my $movieSuggestions;
			if(!checkMovieInfoSearched($movieName)) { 
				$movieSuggestions = getTasteKidListFromAPI($movieName); 
				if ($movieSuggestions ne getDBRawSuggestions($movieName)) { addSuggestions($movieName); }
			} else { $movieSuggestions = getDBRawSuggestions($movieName); }
			
			my ($movieTrailer, $embedable);
			my $verifyTrailer = checkTrailerExistence($movieName);
			if (!$verifyTrailer) {
				my $url = getGoogleTrailerURL($movieName);
				my $movedURL = getGooglesNestedURL($url);
				if($movedURL) {$embedable = checkEmbedable($movedURL);} else {$embedable = 0; $movedURL="http://www.imdb.com";}
				if($embedable) {$movedURL =~ s/watch\?v=/embed\//i;}
				$movieTrailer = $movedURL;
			} else {
				$movieTrailer = "";
				$embedable = "";
			}
			my ($dbTrailer, $dbEmbedable) = getDBTrailerUrl($movieName);
			chomp($dbTrailer); chomp($movieTrailer);
			#Return the collected information as XML:
			if (($movieTrailer ne $dbTrailer || $embedable ne $dbEmbedable) && ($movieTrailer ne "" && $embedable ne "")) { 
				addTrailerUrl($movieName, $movieTrailer, $embedable); 
				writeMovieRowXMLToBrowser($qid, $movieName, $movieRating, $movieGenre, $movieSuggestions, $movieCover, $movieTrailer, $embedable, $imdbUrl);
			} else { writeMovieRowXMLToBrowser($qid, $movieName, $movieRating, $movieGenre, $movieSuggestions, $movieCover, $dbTrailer, $dbEmbedable, $imdbUrl);}
		} elsif ($tableType eq "small") {
			writeMovieRowXMLToBrowser($qid, $movieName, $movieRating, $movieGenre, "Obsolete", "Obsolete", "Obsolete", "Obsolete", "Obsolete");
		}		
		#Hele get og set lista på essentiell informasjon per 09.05.2013:
		#	getDBMovieGenre#	getDBTrailerUrl#	getDBSuggestions#	getDBRawSuggestions#	getDBMovieRating# getDBProductionYearByID# getDBPlotByID #getDBIMDBUrl
		#	getBitRateDB #	getResolutionDB#	getDurationDB#	addRating#	addGenre#	addTrailerUrl#	addSuggestions#	setBitRateDB
		exit 0;
	}
	my $getConfig = uri_unescape($cgi->param('getConfig'));
	if(defined($getConfig)) {
		writeConfigXMLToBrowser($rowFactor, $coverCachePlacement, $linkRevisor);
		exit 0;
	}
	my $simplePlotID = uri_unescape($cgi->param('simplePlotID'));
	if(defined($simplePlotID)) {
		writePlotXMLToBrowser($simplePlotID);
		exit 0;
	}
	my $getMovieAfter = uri_unescape($cgi->param('getMovieAfter'));
	if(defined($getMovieAfter)) {		
		my $lastRowColor = uri_unescape($cgi->param('lastRowColor'));
		if(defined($lastRowColor)) {
			writeNextMovieInfoWithXMLToBrowser($getMovieAfter, $lastRowColor);
		} else {
			writeNextMovieInfoWithXMLToBrowser($getMovieAfter);
		}
		exit 0;
	}
	#Repo Functions:	
	#[OK] 1. Get repositories and return info as xml. <-
	#[OK] 2. Get all settings for a repository - show contents of conf file as xml.
	#[OK] 3. Update contents of conf file/repo with post of confighash and scalar text variable containing configset path. <-
	#[OK] 4. Create new repository:
	#	[OK] a) Check if exists, If exists already show error, if exists and disabled, then enable.
	#	[OK] b) establish conf file 
	#	[OK] c) establish perl file
	#	[OK] d) establish symlink
	#   [OK] e) update db about the repo
	#[OK] 5. Disable or delete repository
	#[OK] 6. Update master-config.conf 
	#[OK] 7. Update repository comment
	#[OK] 8. Get status of master-config.conf
	
	#[OK] 1. Get repositories and return info as xml.
	my $getRepositories = uri_unescape($cgi->param('getRepositories'));
	if(defined($getRepositories)) {
		writeRepositoriesXMLToBrowser(getDBAllRepositories());
		exit 0;
	}
	#[OK] 2. Get all settings for a repository - show contents of conf file as xml.
	my $getWholeConfigset = uri_unescape($cgi->param('getWholeConfigset'));
	if(defined($getWholeConfigset)) {
		writeWholeConfigsetXMLToBrowser($getWholeConfigset);
		exit 0;
	}
	#[OK] 3. Update contents of conf file/repo with post of confighash and scalar text variable containing configset path.
	#[OK] 6. Update master-config.conf - the code below is sufficient for both point 3 and 6.
	my $JSONconfigset = uri_unescape($cgi->param('JSONconfigset'));
	my $setRepository = uri_unescape($cgi->param('setRepository'));
	my $createRepo = uri_unescape($cgi->param('createRepo'));
	# Here starts the updating:
	if(defined($JSONconfigset) && defined($setRepository) && (!defined($createRepo) || !$createRepo)) {
		my $configurationSetSetup = ConfigReader::Simple->new($setRepository);
		my $json = JSON->new->allow_nonref;
		my %configHash = %{ $json->decode($JSONconfigset) };
		foreach my $key (keys %configHash) {
			$configurationSetSetup->set($key, $configHash{$key});
		}
		$configurationSetSetup->save($setRepository) || writeErrorXMLToBrowser("Some error was encountered, error level  replied was: " . $!);
		writeOKXMLToBrowser("Everything looks ok - ".$setRepository." was updated.");
		exit 0;
	#[OK] 4. Create new repository:
	} elsif(defined($JSONconfigset) && defined($setRepository) && $createRepo) {
		my $repo_r = getDBRepository($setRepository);
		if($repo_r) {
			my @repo = @$repo_r;
			foreach (@repo) {
				if(!($_->[1])) {
					enableDBConfset($_->[0]); #a) Enable confset if it exists already
				} else {
					writeErrorXMLToBrowser("Configset '".$_->[0]."' already exists and is already enabled. No new repository was created.");
				}
			}
		} else {
			#b) Establish config file:
			$setRepository = "/etc/movieLister/".$setRepository if(lc(substr($setRepository, 0, 16)) ne lc("/etc/movieLister"));
			my $json = JSON->new->allow_nonref;
			my %configHash = %{ $json->decode($JSONconfigset) };
			if(-d "/etc/movieLister" && -e "/usr/share/movieLister/setup/config_template.conf") {
				my $errorMessage;
				copy("/usr/share/movieLister/setup/config_template.conf",$setRepository) or $errorMessage = "Copy of config_template.conf failed: '/usr/share/movieLister/setup/config_template.conf' to '".$setRepository."': $!. No new repository was created.";
				#Følgende verdier må sendes over:
				#moviePlacement = {pathToMovies} 	#urlMoviePlacement = movieLister/symlinks/{symlinkToPathToMovies}
				#dbUser = {db_User} 				#dbPassword = {db_Password}
				#tasteKidF = {tasteKidF} 			#tasteKidK = {tasteKidK}
				if(!defined($errorMessage)) {
					my $configurationSetSetup = ConfigReader::Simple->new($setRepository) or $errorMessage = $! . ". No new repository was created.";
					foreach my $key (keys %configHash) {
						my $keyContent;
						if($key ne "listHeading" && $key ne "dbUser" && $key ne "dbPassword" && $key ne "currentMoviesPerPage" && $key ne "movieNameOffset" && $key ne "updateInterval" && $key ne "tableType" && $key ne "sambaUsage" && $key ne "numberOfRecomendations" && $key ne "numberOfMoviesBeforeDBTakeOver" && $key ne "youtubeEmbedString" && $key ne "tastekidString" && $key ne "neverEmbed" && $key ne "tasteKidF" && $key ne "tasteKidK" && $key ne "forcedTasteKidAPI" && $key ne "") {
							$keyContent	= checkTrailingSlash($configHash{$key});
						} else {
							$keyContent = $configHash{$key};
						}
						$keyContent =~ s/\s+$//; $keyContent =~ s/^\s+//; #remove trailing spaces #remove leading spaces
						$configHash{$key} = $keyContent; #Store the changed key contents for further usage
						$configurationSetSetup->set($key, $keyContent);
					}
					$configurationSetSetup->save($setRepository) or $errorMessage = $!;
				} 				
				if(defined($errorMessage)) {
					writeErrorXMLToBrowser($errorMessage);
					#Clean up what we have made:
					if(-e $setRepository) {
						`rm $setRepository`;
					}
					exit 1;
				} 
			} else {
				writeErrorXMLToBrowser("Either /etc/movieLister or /usr/share/movieLister/setup/config_template.conf does not exist.");
				exit 1;
			}
			#c) Establish perl file:
			my @confsetupNameSplit = split('/',$setRepository);
			my $confsetupName = $confsetupNameSplit[((scalar @confsetupNameSplit) - 1)];
			my @confsetupNameSplitAgain = split(".",$confsetupName);
			my $perlFileName = (lc(substr($confsetupName, -5)) eq ".conf" ? substr($confsetupName, 0, -5) : $confsetupName);
			
			#$confsetupName = $confsetupNameSplitAgain[0];
			if(!defined($confsetupName) || $confsetupName eq "" || !defined($perlFileName) || $perlFileName eq "") {
				writeErrorXMLToBrowser("confSetupName is empty after deriving value from setRepository '" . $setRepository . "', split into '" . (scalar @confsetupNameSplit) . "', split again into: '" . (scalar @confsetupNameSplitAgain) . "', using name for perl file:'".$perlFileName."'. No new repository was created.");				
				#Clean up what we have made:					
				`rm $setRepository` if(-e $setRepository);
				exit 1;
			}
			if(-d "/usr/share/movieLister/symlinks" && -e "/usr/share/movieLister/setup/start-template.pl") {
				my $errorMessage;
				copy("/usr/share/movieLister/setup/start-template.pl","/usr/share/movieLister/cgi-bin/" . $perlFileName . ".pl") or $errorMessage = "Copy of start-template.pl failed: $!. No new repository was created.";
				if(!defined($errorMessage)) {
					#{name} is replaced:
					my $lFilename = "/usr/share/movieLister/cgi-bin/" . $perlFileName . ".pl";
					open(FILE, "<" . $lFilename) or $errorMessage = "File $perlFileName.pl not found for reading. No new repository was created.";
					my @lines = <FILE>;
					close(FILE);
					my @newlines;
					foreach(@lines) {
					   $_ =~ s/\{name\}/$perlFileName/g;
					   push(@newlines,$_);
					}
					open(FILE, ">" . $lFilename) or $errorMessage = "File $perlFileName.pl not found for writing. No new repository was created.";
					print FILE @newlines;
					close(FILE);
					chmod 0744, $lFilename or $errorMessage = "Couldn't chmod $lFilename: $!. No new repository was created."
				}
				if(defined($errorMessage)) {
					writeErrorXMLToBrowser($errorMessage);
					#Clean up what we have made:					
					`em $setRepository` if(-e $setRepository);
					my $cFile = "/usr/share/movieLister/cgi-bin/" . $perlFileName . ".pl";
					`rm $cFile` if(-e $cFile);
					exit 1;
				}
			} else {
				writeErrorXMLToBrowser("Either /usr/share/movieLister/symlinks or /usr/share/movieLister/setup/start-template.pl does not exist. No new repository was created.");
				#Clean up what we have made:					
				`rm $setRepository` if(-e $setRepository);
				my $cFile = "/usr/share/movieLister/cgi-bin/" . $perlFileName . ".pl";
				`rm $cFile` if(-e $cFile);
				exit 1;
			}
			#d) Create a symlink:
			my $tempHardMoviePlacement = $configHash{"hardMoviePlacement"};
			$tempHardMoviePlacement =~ s/\/+$//; #remove leading slashes
			my $tempMoviePlacement = $configHash{"moviePlacement"};
			$tempMoviePlacement =~ s/\/+$//; #remove leading slashes
			
			my $errorMessage;			
			symlink($tempHardMoviePlacement, $tempMoviePlacement) or $errorMessage = "Symlink between '" . $configHash{"hardMoviePlacement"} . "' and '" . $configHash{"moviePlacement"} . "' failed: $!. No new repository was created.";
			if(!defined($errorMessage)) {
				#e) Update db about the repo:
				setConfsetDB($setRepository, $perlFileName) or $errorMessage = "Failed to register confset '".$setRepository."' in database: $!. No new repository was created.";
				writeOKXMLToBrowser("Repository with config '" . $setRepository . "' was created! Success!") if(!defined($errorMessage));
			}
			if(defined($errorMessage)) {
				#Clean up what we have made:					
				`rm $setRepository` if(-e $setRepository);
				my $cFile = "/usr/share/movieLister/cgi-bin/" . $perlFileName . ".pl";
				`rm $cFile` if(-e $cFile);
				my $symFile = $tempMoviePlacement;
				`unlink $symFile` if(-e $symFile);
				writeErrorXMLToBrowser($errorMessage);
				exit 1;
			}
		}
		exit 0;
	}
	#[OK] 5. Disable or delete repository
	my $disableRepository = uri_unescape($cgi->param('disableRepository'));
	my $deleteRepository = uri_unescape($cgi->param('deleteRepository'));
	if(defined($disableRepository)) {
		if(substr($disableRepository, 0, 17) ne "/etc/movieLister/") {$disableRepository = "/etc/movieLister/" . $disableRepository;}
		my $errorMessage;
		disableDBConfset($disableRepository) or $errorMessage = "Was not able to disable repository '" . $disableRepository . "'";
		if(defined($errorMessage)) {
			writeErrorXMLToBrowser($errorMessage);
		} else {
			writeOKXMLToBrowser("Disabeling of repository '".$disableRepository."' confirmed.");
		}
		exit 0;
	}
	if(defined($deleteRepository)) {
		my $perlFileName = "";
		if(substr($deleteRepository, 0, 17) ne "/etc/movieLister/") {
			$perlFileName = $deleteRepository . ".pl";
			$deleteRepository = "/etc/movieLister/" . $deleteRepository . ".conf";
		}
		my $errorMessage = "Error: ";
		my $localConfigSetup = ConfigReader::Simple->new($deleteRepository);
		my $tempMoviePlacement = $localConfigSetup->get("moviePlacement");
		chop($tempMoviePlacement);
		deleteDBConfset($deleteRepository) or $errorMessage .= "Was not able to delete repository '" . $deleteRepository . ".'";
		if(-e $deleteRepository) {
			`rm $deleteRepository`; 
			$errorMessage .= " Could not delete configuration file '".$deleteRepository.".'" if(-e $deleteRepository);			
		} else {$errorMessage .= " Configuration file '".$deleteRepository.".' was not found and therefore can not be deleted.";}
		my $cFile = "/usr/share/movieLister/cgi-bin/" . $perlFileName;
		if(-e $cFile) {
			`rm $cFile`;
			$errorMessage .= " Could not delete '".$cFile.".'" if(-e $cFile);
		} else {$errorMessage .= " File '".$cFile.".' was not found and therefore can not be deleted.";}
		my $symLink = $tempMoviePlacement;
		if(-l $symLink) {
			`unlink $symLink`;
			$errorMessage .= " Could not unlink '".$symLink.".'" if(-l $symLink);
		} else {$errorMessage .= " Symlink '".$symLink.".' was not found and therefore can not be deleted."}
		
		if(defined($errorMessage) and $errorMessage ne "") {
			writeErrorXMLToBrowser($errorMessage);
		} else {
			writeOKXMLToBrowser("Deletion of repository '".$deleteRepository."' confirmed.");
		}
		exit 0;
	}
	#[OK] 7. Update repository comment
	my $updateRepoComment = uri_unescape($cgi->param('updateRepoComment'));
	my $repoConfset = uri_unescape($cgi->param('confset'));
	if(defined($updateRepoComment)) {
		my @reply = updateDBRepoComment("/etc/movieLister/".$repoConfset, $updateRepoComment);
		if(!$reply[0][0]) {
			writeErrorXMLToBrowser("Unable to update repository " . $updateRepoComment . " with comment. " . $reply[0][1]);
		} else {
			writeOKXMLToBrowser("All looks OK, script replied: " . $reply[0][1]);
		}
		exit 0;
	}
	#[OK] 8. Get status of master-config.conf
	my $getMainConfigset = uri_unescape($cgi->param('getMainConfigset'));
	if(defined($getMainConfigset)) {
		writeMainConfigsetXMLToBrowser();
		exit 0;
	}
	#[OK] 9. validateMainConfiguration
	my $validateMainConfiguration = uri_unescape($cgi->param('validateMainConfiguration'));
	if(defined($validateMainConfiguration)) {
		my $dbh;
		if($dbh=DBI->connect('dbi:mysql:movie_info_db',getDbUser(),getDbPassword(),{AutoCommit => 0})) {
			if($dbh->disconnect) {
				writeOKXMLToBrowser("All looks OK - database connection validated");
			} else {
				writeErrorXMLToBrowser("Failed to disconnect from database");
			}
		} else {
			writeErrorXMLToBrowser("Error opening database at validateMainConfiguration: $DBI::errstr");
		}
		exit 0;
	}
}
#<-- End of area for url query parsing.

my @movieContainer;
my $noMovies = getNoMoviesFromDisk($moviePlacement);
my $dbNoMovies = getTotalNoMoviesFromEnv();

##GET DATA READY FOR DISPLAY:

if(($noMovies != $dbNoMovies) && ($dbNoMovies > $numberOfMoviesBeforeDBTakeOver)) {
	#We update db cache with what has changed on disk since last load, and build the movieLister web page from that:
	chop($moviePlacement);
	opendir(DIR,$moviePlacement);
	my @movieContainer_temp = readdir(DIR);
	closedir(DIR);
	$moviePlacement = $moviePlacement . "/";
	foreach (@movieContainer_temp) {
		push(@movieContainer, $moviePlacement . $_);
	}
	setDiskDifferenceToMovieCache(\@movieContainer);
	$noMovies = (scalar @movieContainer) - 2;
} elsif($dbNoMovies <= $numberOfMoviesBeforeDBTakeOver) {
	#We build the movieLister web page from what is on disk only:
	chop($moviePlacement);
	opendir(DIR,$moviePlacement);
	my @movieContainer_temp = readdir(DIR);
	closedir(DIR);
	$moviePlacement = $moviePlacement . "/";
	foreach (@movieContainer_temp) {
		push(@movieContainer, $moviePlacement . $_);
	}
	$noMovies = (scalar @movieContainer) - 2;
	setNoMoviesInEnv($noMovies);
	setMovieListCache(\@movieContainer);
} else {
	#We build the movieLister web page from what is stored and cached in DB only:
	my $movieContainer_r = buildMovieContainerFromCache();
	@movieContainer = @$movieContainer_r;
	$noMovies=getTotalNoMoviesFromEnv();
}

my @urlSplit = split('/', $cgi->self_url());
#DNS name is unused in the script as of this version
#my $dnsName = $urlSplit[2];
my $scriptName = $urlSplit[((scalar @urlSplit)-1)];
my $numberOfPages = $currentMoviesPerPage ? round(($noMovies/$currentMoviesPerPage)) : round(($noMovies/1));
my $sambaProcStatus = 2;
my $isShared = 2;

my $value;
if($ENV{'QUERY_STRING'}) {
	$value = $cgi->param('Page');
	if(!intCheck($value)) {$value = 0;}
	if($value < 0) {$value = 0;} else { $value = $value - 1;}
	if($value > ($numberOfPages - 1)) {$value = $numberOfPages - 1;}
	if(($value * $currentMoviesPerPage) < $noMovies) {
		if($value == -1) {
			$currentMoviesPerPage = $noMovies;
			$currentPagePosition = 0;
		} else {
			$currentPagePosition = $value * $currentMoviesPerPage;
		}
	} else {
		$currentPagePosition = ($noMovies / $currentMoviesPerPage) - 1;
	}
}
if(!$value) {$value = 0;}
#print "Movies counted from disk: ", $temprr . ", counted from database: " . $dbNoMovies . ", entered says: " . $entered ."<br/>";

##HERE THE MOVIE LISTER TABLE STARTS:
##START OF HTML AREA
print $cgi->header(), $cgi->start_html(-title=>$listHeading,-onload=>'display_footer_message();', onscroll=>'movediv();',-style=>[
 {-src=>'/' . $styleSheetPlacement . 'movieStyle.css'},
 {-src=>'/' . $styleSheetPlacement . 'lightbox.css', -media=>'screen'}],
 -script=>[{-type=>'JAVASCRIPT', -code=>'var urlImagePlacement = "' . $urlImagePlacement . '";'},
 {-type=>'JAVASCRIPT', -src=>'http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js'},
 {-type=>'JAVASCRIPT', -src=>'/' . $javaScriptPlacement . 'prototype.js'},
 {-type=>'JAVASCRIPT', -src=>'/' . $javaScriptPlacement . 'scriptaculous.js?load=effects,builder'},
 {-type=>'JAVASCRIPT', -src=>'/' . $javaScriptPlacement . 'lightbox.js'},
 {-type=>'JAVASCRIPT', -src=>'/' . $javaScriptPlacement . 'movieLister.js'}]);
if ($tableType eq "small") {
	print $cgi->span({-id=>'header_showbar', -style=>'text-align:center;'},$cgi->span({-class=>'movieHeader-small', -style=>'text-align:center;'}, $listHeading));
} else {
	print $cgi->span({-id=>'header_showbar', -style=>'text-align:center;'},$cgi->span({-class=>'movieHeader', -style=>'text-align:center;'}, $listHeading));
}
print $cgi->br . $cgi->br . $cgi->br;
print $cgi->span({-id=>'pre_loading', -align=>'center'},'Loading..' . $cgi->br.$cgi->br.$cgi->br.$cgi->span({-id=>'pre_loading_bottom'}, 'Please wait..'));

createHTMLTable(\@movieContainer, \$moviePlacement, \$urlMoviePlacement, \$currentPagePosition, \$currentMoviesPerPage);

print "\n";
print $cgi->div({-id=>'footer_controlbar'},'<center>'.
"<table border=\"0\" align=\"center\" cellspacing=\"0\" width=\"100%\">" .
"<tr>" .
"<td></td>" .
"<td align=\"right\" width=\"32\" style=\"cursor: pointer; background-color: #FFFFFF;border:4px solid;border-color: #577171;\"><img src=\"/".$urlImagePlacement."reload-1.png\" title=\"Reload all movies from database\" id=\"footerReloadButton\" height=\"36\" width=\"32\" OnClick=\"flashAndSubmitReloadButton('footerReloadButton', '".$thisScriptName."')\" OnMouseOver=\"onMouseOverReloadButton('footerReloadButton')\" OnMouseOut=\"document.getElementById('footerReloadButton').src='/".$urlImagePlacement."reload-1.png';\" alt=\"Reload page..\" /></td>" .
"<td width=\"200\" valign=\"center\" align=\"center\"><form action=\"/movieLister/cgi-bin/" . $scriptName . "\" method=\"GET\" id=\"navigationForm\">" .
$cgi->a({-href=>"#Prev", -class=>'navigation', -onclick=>"navigationSubmit('prev','tableStampSize')"}, "Prev") . "&nbsp;<input type=\"text\" name=\"Page\" id=\"pageNumberHolder\" size=\"1\" value=\"". ($value + 1) ."\" class=\"pageNumberHolder\"><input type=\"hidden\" name=\"pageSize\" id=\"pageSize\" size=\"0\" value=\"". $tableType ."\">&nbsp;". $cgi->a({-href=>"#Next", -class=>'navigation', -onclick=>"navigationSubmit('next','tableStampSize')"}, "Next") .
"</form><center><font style=\"color: black; font-family: BladeRunner; font-size: 10pt\" OnMouseOver=\"changePositionFont('Red');\" OnMouseOut=\"changePositionFont('Black');\" id=\"positionFont\">" . ($currentMoviesPerPage ? (($currentPagePosition/$currentMoviesPerPage)+1) : (($currentPagePosition/1)+1)) . " of <span id=\"numberOfPages\" value=\"".$numberOfPages."\">" . $numberOfPages . "</span></font></center>" .
"<td align=\"left\" width=\"32\" style=\"cursor: pointer; background-color: #FFFFFF;border:4px solid;border-color: #577171;\"><img src=\"/".$urlImagePlacement."stamp".$tableType .".png\" id=\"tableStampSize\" title=\"Choose table size at next navigation\" height=\"36\" width=\"32\" OnClick=\"stampRotate('tableStampSize')\" /></td>" .
"<td></td>" .
"</tr></table>" .
'</center>');# if ($tableType ne "small");
print $cgi->div({-id=>'bottom_controlbar_controller'},$cgi->img({src=>'/'.$urlImagePlacement.'minusSign_small_white.png',align=>'LEFT',id=>'bottom_barsign',title=>'Toggle Bottom bar'}));# if ($tableType ne "small");
print $cgi->div({-id=>'footer_controlbar_controller'},$cgi->img({src=>'/'.$urlImagePlacement.'plusSign_small.png',align=>'LEFT',id=>'footer_barsign',title=>'Toggle Navigation bar'}));# if ($tableType ne "small");
print $cgi->br;
print $cgi->div({-id=>'bottom_controlbar'},'<center>'."<table border=\"0\" align=\"center\" cellspacing=\"0\" width=\"100%\">"."<tr>"."<td></td>"."<td align=\"right\" width=\"46\" style=\"cursor: pointer ;background-color: #FFFFFF;border:4px solid;border-color: #577171;\"><img src=\"/".$urlImagePlacement."reload-1.png\" title=\"Reload movie rows without reset of page\" id=\"bottomReloadButton\" height=\"50\" width=\"46\" OnClick=\"flashAndSubmitReloadButton('bottomReloadButton', '".$thisScriptName."')\" OnMouseOver=\"onMouseOverReloadButton('bottomReloadButton')\" OnMouseOut=\"document.getElementById('bottomReloadButton').src='/".$urlImagePlacement."reload-1.png';\" alt=\"Reload page..\" /></td>"."<td width=\"200\" valign=\"center\" align=\"center\"><form action=\"/movieLister/cgi-bin/" . $scriptName . "\" method=\"GET\" id=\"navigationForm\">".$cgi->a({-href=>"#Prev", -class=>'navigation', -onclick=>"navigationSubmit('prev','tableStampSizeBottom')"}, "Prev") . "&nbsp;<input type=\"text\" name=\"Page\" id=\"pageNumberHolder\" size=\"1\" value=\"". ($value + 1) ."\"><input type=\"hidden\" name=\"pageSize\" id=\"pageSize\" size=\"0\" value=\"". $tableType ."\">&nbsp;". $cgi->a({-href=>"#Next", -class=>'navigation', -onclick=>"navigationSubmit('next','tableStampSizeBottom')"}, "Next")."</form></td>"."<td align=\"left\" width=\"46\" style=\"cursor: pointer; background-color: #FFFFFF;border:4px solid;border-color: #577171;\"><img src=\"/".$urlImagePlacement."stamp".$tableType .".png\" id=\"tableStampSizeBottom\" title=\"Choose table size at next navigation\" height=\"50\" width=\"46\" OnClick=\"stampRotate('tableStampSizeBottom')\"/></td>"."<td></td>"."</tr></table>".'</center>');
print $cgi->span({-id=>'plotMessageBox', -class=>'plotMessageBox'},'');
print $cgi->span({-id=>'bottom_breaklines'},$cgi->br . $cgi->br);

print $cgi->end_html();
##END OF HTML AREA

sub initiateMovieCover {
	my $movieName = shift;
	#1. Get movie cover URL from moved URL and update rating
	my $imageLink = getImageLink($movieName);
	#2. Store local URL in database if it is valid:
	if(!$imageLink) { return "<img src=\"/". $urlImagePlacement . "warning.png\" width=\"". ($rowFactor*97) ."\" height=\"". ($rowFactor*125) ."\" alt=\"Cover Not Found\" />"; }
	chomp($imageLink);
	if(checkDBConnection()) {
		addMovie($movieName, $imageLink);
		checkAndGetMovieRatingInDB($movieName);
	}
	#3. Return cover
	chomp($imageLink);	
	my $imageFile = getLastFromURL($imageLink);		
	return "<a href=\"/". $coverCachePlacement . $imageFile ."\" rel=\"lightbox\" title=\"". $movieName ."\"><img src=\"" . $coverCachePlacement . $imageFile . "\" width=\"". ($rowFactor*89) ."\" height=\"". ($rowFactor*157) ."\" alt=\"". $movieName ."\" /></a>";
}
sub initiateMovieInfo {
	##This sub is the main collector of data from the internet. 
	##If data is not found in DB, this sub is called to collect it all.

	my $movieName = shift;
	if($_[1]) {my $movieNameOffset = shift;}
	if($_[2]) {my $webRoot = shift;}
	if($_[3]) {my $coverCachePlacement = shift;}
	if($_[4]) {my $numberOfRecomendations = shift;}
	
	if(defined($movieName)) {
		$movieName = substr $movieName, $movieNameOffset;
		$movieName = nameProcessor($movieName);
		#The Following section is for troubleshooting purposes:
		#my $parent = ( caller(1) )[3];
		#print "Executed from $parent <br/>";
		#print "Got $movieName - $movieNameOffset - $webRoot - $coverCachePlacement - $numberOfRecomendations <br/><br/>";
		
		#0. Check if movieName is already searched for
		#1. Check if rating is in DB
		#2. Check if movie cover exists in DB
		#3. Check if genre exists in DB
		#4. If one is missing, get all from same lookup at IMDB
		if(!checkMovieInfoSearched($movieName)) {
			#print " - Failed initial check with " . $movieName . "<br/>";
			if(!checkYearExistence($movieName) || !checkIMDBUrlExistence($movieName) || !checkUrlExistence($movieName) || !checkTrailerExistence($movieName) || !checkGenreExistence($movieName) || !checkPlotExistence($movieName)) {
				my $infoArray_r = getMovieInfo($movieName);
				my @infoArray = @$infoArray_r;
				my $imageLink = $infoArray[0];
				my $genre = $infoArray[1];
				my $rating = $infoArray[2];
				my $imdbUrl = $infoArray[3];
				my $plot = $infoArray[4];
				my $year = $infoArray[5];
				#print "   Got -->" . $rating . " " . $imageLink . " " . $genre . "\n<br/>";
				if($imageLink && ref $imageLink ne ref {}) { 
					chomp($imageLink);
					my $imageFile = getLastFromURL($imageLink);
					chomp($imageFile);
					unless (-e $webRoot . $coverCachePlacement . $imageFile) {getstore($imageLink, $webRoot . $coverCachePlacement . $imageFile);}
					addMovie($movieName, $imageLink);
				}
				if($imageLink && ref $imageLink eq ref {}) { 
					my $hashReference = $imageLink;
					#foreach my $key ( keys %{ $hashReference } ){
						$imageLink = ${$hashReference}{"imdb"}; #We are only interested in the poster that lies within the imdb key in the hash.
						#print "   Got --> key: '" . $key . "' with link '" . $imageLink . "'\n<br/>";
						chomp($imageLink);
						my $imageFile = getLastFromURL($imageLink);
						chomp($imageFile);
						unless (-e $webRoot . $coverCachePlacement . $imageFile) {getstore($imageLink, $webRoot . $coverCachePlacement . $imageFile);}
					#}
					addMovie($movieName, ${$hashReference}{"imdb"});
				}
				addGenre($movieName, $genre) if($genre ne " ");
				addRating($movieName, $rating) if($rating);
				setTrailerToDB($movieName);
				addIMDBUrl($movieName, $imdbUrl) if($imdbUrl);
				addPlot($movieName, $plot) if($plot);
				addYear($movieName, $year) if($year);
			}
			#B. Now check for TasteKidList info:
			if(!checkTasteKidList($movieName)) {	
				my $tasteList = getTasteKidListFromAPI($movieName, $forcedTasteKidAPI);
				if(defined($tasteList)){ addSuggestions($movieName, $tasteList);}
			}
			setMovieInfoSearched($movieName, 1);
		}
	}
}
sub getMovieInfo {
	my $movieName = shift;
	my $processedMovieName = nameProcessor($movieName);
	my $searching = 1;
	my $imageLink = "";
	my $imdburl = "";
	my $rating = 0;
	my $genre = "Unknown";
	my $plot = "Unknown";
	my $year = "Unknown";
	#This loop will run maximum twice. Again if the moviename ends in a four digit number and we didn't find anything the first time.
	#The second time it runs it will be without the four digit number at the end of the movie name.
	while($searching) {
		my $xmlDoc = XML::Mini::Document->new();
		#1. Thus URL will give us an XML document to parse:
		my $url = "http://mymovieapi.com/?title=".uri_escape($processedMovieName)."&type=xml&plot=simple&episode=1&limit=1&yg=0&mt=none&lang=en-US&offset=&aka=simple&release=simple&business=0&tech=0";
		#print "<b>".$processedMovieName."</b> - Trying: <font size=\"-1\">" . $url . "</font><br/>";
		#2. Download the url and extract the information(imageLink/cover: OK, genre: OK, rating: OK):
		my $xml;
		$genre = " ";
		#print "Called getMovieInfo() for " . $movieName . "<br/> - " . $processedMovieName . "<br/> - ".removeNoiseWords(lc($movieName))."<br/><br/>";
		if($url =~ /http/) {
			#print "   URL OK!<br/>";
			my $response_body = tempfile();
			my $curl = WWW::Curl::Easy->new;

			$curl->setopt(CURLOPT_HEADER, 1);
			$curl->setopt(CURLOPT_URL, $url);
			$curl->setopt(CURLOPT_WRITEDATA, $response_body);

			my $return_code = $curl->perform;
		
			my $getNextLine = 0;
			if ($return_code == 0) {
				my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
				seek($response_body, 0, SEEK_SET);     # reset filehandle to beginning of file
				while (<$response_body>) {
					$xml .= $_;
				}
				$xmlDoc->parse($xml);
				my $xmlHash = $xmlDoc->toHash();
				$rating = $xmlHash->{'IMDBDocumentList'}->{'item'}->{'rating'};
				if(ref $xmlHash->{'IMDBDocumentList'}->{'item'}->{'genres'}->{'item'} eq 'ARRAY') {
					foreach my $genreElement (@{$xmlHash->{'IMDBDocumentList'}->{'item'}->{'genres'}->{'item'}}) {
						$genre .= $genreElement . " ";
					}
				} else {
					$genre .= $xmlHash->{'IMDBDocumentList'}->{'item'}->{'genres'}->{'item'} if(exists($xmlHash->{'IMDBDocumentList'}->{'item'}->{'genres'}->{'item'}));
				}
				if(ref $xmlHash->{'IMDBDocumentList'}->{'item'}->{'poster'} eq 'ARRAY') {
					foreach my $imageLinkElement (@{$xmlHash->{'IMDBDocumentList'}->{'item'}->{'poster'}}) {
						$imageLink .= $imageLinkElement . " ";
					}
				} else {
					$imageLink = $xmlHash->{'IMDBDocumentList'}->{'item'}->{'poster'};
				}
				$imdburl = $xmlHash->{'IMDBDocumentList'}->{'item'}->{'imdb_url'};
				$plot = $xmlHash->{'IMDBDocumentList'}->{'item'}->{'plot_simple'};
				$year = $xmlHash->{'IMDBDocumentList'}->{'item'}->{'year'};
			} elsif($return_code == 56) {
				#If the return code is 56, then we have been interrupted. We loop and try again.
				$searching = 1;
				next;
			} else {
				print ("An error occured: ".$return_code." ".$curl->strerror($return_code)." ".$curl->errbuf." at initiateMovieInfo() when treating ". $url ."\n");
			}
			#print "   -->" . $rating . " " . $imageLink . " " . $genre . "<br/>";
		}
		if(defined($rating)) {undef($rating) if($rating eq "");}
		if(defined($year)) {undef($year) if($year eq "");}
		#If movie name does not end as a single word in 4 digits or does not start and end as a single word with 4 digits, we consider searching as done:
		if($processedMovieName !~ m/\b\d{4}\b$/ || $processedMovieName =~ m/\b^\d{4}\b$/){$searching = 0;}
		#If movie name does end as a single word in 1 to 4 digits and rating is not defined, we remove those last 1 to 4 digits:
		if($processedMovieName =~ m/\b\d{1,4}\b$/ && !defined($rating)){$processedMovieName =~ s/\b\d{1,4}\b$//;}
		#If we have have found a rating, or the production year, then we consider the search as done - we specify this here just to be safe:
		if(defined($rating) || defined($year)) {$searching = 0;}
	}
	$imageLink =~ s/\s+$// if(defined($imageLink)); #remove trailing spaces
	if(defined($genre)) { $genre =~ s/\s+$//; $genre =~ s/^\s+//;} #remove trailing spaces #remove leading spaces
	my @infoArray = ($imageLink, $genre, $rating, $imdburl, $plot, $year);
	return \@infoArray;
}
sub createInfoArrayFromDB {
	my $movieName = shift;
	my $processedMovieName = nameProcessor($movieName);
	my ($imageLink, $rating, $genre, $imdburl, $plot, $year);
	$imageLink = checkUrlExistence($movieName);
	$imageLink = "/" . $urlImagePlacement . "warning.png" if(!defined($imageLink) || !$imageLink);
	$rating = getDBMovieRating($movieName);
	$genre = getDBMovieGenre($movieName);
	$imdburl = getDBIMDBUrl($movieName);
	$plot = getDBPlotByID(getMovieIDByMovieName($movieName));
	$year = getDBProductionYearByID(getMovieIDByMovieName($movieName));
	my @infoArray = ($imageLink, $genre, $rating, $imdburl, $plot, $year);
	return \@infoArray;
}
sub getTasteKidListFromAPI {
	my $movieName = shift;
	my $forcedAPIUsage = shift; #Do not define or set to 0 to disable, any other value enables
	my $tasteKidUrl = "http://www.tastekid.com/like/". uri_escape(nameProcessor($movieName)) ."/movies";
	my $tasteList;
	
	if(!defined($forcedAPIUsage)) {$forcedAPIUsage = 0;}
	if(!$forcedAPIUsage) {
		#print "Getting from URL for: " . nameProcessor($movieName) . "<br/>";
		my $response_body = tempfile();
		my $curl = WWW::Curl::Easy->new;

		$curl->setopt(CURLOPT_HEADER, 1);
		$curl->setopt(CURLOPT_URL, $tasteKidUrl);
		$curl->setopt(CURLOPT_WRITEDATA, $response_body);

		my $return_code = $curl->perform;
		
		if ($return_code == 0) {
			my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
			seek($response_body, 0, SEEK_SET);     # reset filehandle to beginning of file
			while (<$response_body>) {
				if($_ =~ /$tastekidString/) {
					my @tasteListSplit = split(/\,/,$_);
					for (my $innerCounter = 0; $innerCounter < $numberOfRecomendations+1; $innerCounter++) {
						$tasteListSplit[$innerCounter+1] =~ s/^\s+//; #remove leading spaces $numberOfRecomendations
						$tasteListSplit[$innerCounter+1] =~ s/\s+$//; #remove trailing spaces
						if(!($tasteListSplit[$innerCounter+1] =~ /suggest/) && !($tasteListSplit[$innerCounter+1] =~ /recommend/) && !($tasteListSplit[$innerCounter+1] =~ /like/) && !($tasteListSplit[$innerCounter+1] =~ /similar/) && !($tasteListSplit[$innerCounter+1] =~ /taste/) && !($tasteListSplit[$innerCounter+1] =~ /recommendation/) && !($tasteListSplit[$innerCounter+1] =~ /related/)) {
							$tasteList .= $tasteListSplit[$innerCounter+1] . " - ";
						}
					}
				}
			}
		} else {
			print ("An error occured: ".$return_code." ".$curl->strerror($return_code)." ".$curl->errbuf." at getTasteKidListFromAPI() when treating ". $tasteKidUrl ."\n");
		}
	}
	if(defined($tasteList) && $tasteList !~ /\"\=\+\?\%\!{3,}\#\'\[\]\*\{\{/) {
		chop($tasteList);
		chop($tasteList);
		chop($tasteList);
		return $tasteList;
	} else {
		#Get from API - http://www.tastekid.com/page/api
		#Thank you, creators of tastekid.com! =)
		my $preparedMovieName = nameProcessor(lc($movieName));
		#We dont know if the movie name is supposed to end with a four digit number or not.
		#If the movie name ends with a four digit number, we try to search with that name first, then remove the number and try again if we fail.
		my $searching = 1;
		while($searching) {
			my ($url, $xml);
			my $xmlDoc = XML::Mini::Document->new();
			my $curl = WWW::Curl::Easy->new;
			#my ($response_body, $filename) = tempfile(UNLINK => 1);
			my $response_body = tempfile(UNLINK => 1);
			if($tasteKidK eq "" || $tasteKidF eq "" || !defined($tasteKidK) || !defined($tasteKidF)) {
				$url = "http://www.tastekid.com/ask/ws?q=movie:".uri_escape($preparedMovieName)."//movies";
			} else {
				$url = "http://www.tastekid.com/ask/ws?q=movie:".uri_escape($preparedMovieName)."//movies&f=".$tasteKidF."&k=".$tasteKidK;
			}
			#print "Getting from API for: " . $preparedMovieName . " with url: ".$url."<br/>";
			$tasteList = "";
			$curl->setopt(CURLOPT_HEADER, 1);
			$curl->setopt(CURLOPT_URL, $url);
			$curl->setopt(CURLOPT_WRITEDATA, $response_body);

			my $return_code = $curl->perform;
			my $getNextLine = 0;
			if ($return_code == 0) {
				my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
				seek($response_body, 0, SEEK_SET);     # reset filehandle to beginning of file
				while (<$response_body>) {
					$xml .= $_;
				}
				$xmlDoc->parse($xml);
				my $xmlHash = $xmlDoc->toHash();
				if(defined($xmlHash)) {
					if(exists($xmlHash->{'similar'})) {
						if($xmlHash->{'similar'} ne "" && exists($xmlHash->{'similar'}->{'results'})) {
							if($xmlHash->{'similar'}->{'results'} ne "" && exists($xmlHash->{'similar'}->{'results'}->{'resource'})) {
								if(ref $xmlHash->{'similar'}->{'results'}->{'resource'} eq 'ARRAY') {
									foreach my $tasteResourceHash (@{$xmlHash->{'similar'}->{'results'}->{'resource'}}) {
										$tasteList .= $tasteResourceHash->{'name'}->{'CDATA'}  . " - ";
									}
								} else {
									$tasteList .= $xmlHash->{'similar'}->{'results'}->{'resource'}->{'name'}->{'CDATA'} . " - ";
								}
							}
						}
					}
				}
				if($tasteList eq "") {
					$tasteList = "No suggestions found.." . " - ";
				}
			} else {
				print ("An error occured: ".$return_code." ".$curl->strerror($return_code)." ".$curl->errbuf." at getTasteKidListFromAPI() when treating ". $url ."\n");
			}
			if($preparedMovieName !~ m/\b\d{4}\b$/){$searching = 0;}
			if($preparedMovieName =~ m/\b\d{4}\b$/ && $tasteList eq "No suggestions found.. - "){$preparedMovieName =~ s/\b\d{4}\b$//;}
		}
		chop($tasteList);
		chop($tasteList);
		chop($tasteList);
		return $tasteList;
	}
}
sub getGoogleTrailerURL {
	my $movieName = shift;
	$movieName = nameProcessor($movieName);
	return "http://www.google.com/search?hl=en&q=youtube+" . uri_escape($movieName) . "%20Trailer&btnI=I%27m+Feeling+Lucky";
}
sub getGooglesNestedURL {
	my $url = shift;
	my $movedURL = "";
	my $response_body = tempfile();
	my $curl = WWW::Curl::Easy->new;

	$curl->setopt(CURLOPT_HEADER, 1);
	$curl->setopt(CURLOPT_URL, $url);
	$curl->setopt(CURLOPT_WRITEDATA, $response_body);

	if($url =~ /http/) {
		my $return_code = $curl->perform;
		if ($return_code == 0) {
			my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
			seek($response_body, 0, SEEK_SET);     # reset filehandle to beginning of file
			while (<$response_body>) {
				if($_ =~ /Location:/) {
					$movedURL = substr $_, 10;
					if($movedURL =~ /sorry/) {
						$movedURL = "Sorry, Google is blocking us!";
					}
				}
			}
		} else {
			print ("An error occured: ".$return_code." ".$curl->strerror($return_code)." ".$curl->errbuf." at getGooglesNestedURL()\n");
		}
	}
	if(!$movedURL) { return undef;}
	return $movedURL;
}
sub getImageLink {
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my $url = "http://mymovieapi.com/?title=".uri_escape(nameProcessor($movieName))."&type=xml&plot=none&episode=1&limit=1&yg=0&mt=none&lang=en-US&offset=&aka=simple&release=simple&business=0&tech=0";
	my $imageLink;
	my $xmlDoc = XML::Mini::Document->new();
	my $xml;
	if($url =~ /http/) {
		my $response_body = tempfile();
		my $curl = WWW::Curl::Easy->new;

		$curl->setopt(CURLOPT_HEADER, 1);
		$curl->setopt(CURLOPT_URL, $url);
		$curl->setopt(CURLOPT_WRITEDATA, $response_body);

		my $return_code = $curl->perform;

		if ($return_code == 0) {
			my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
			seek($response_body, 0, SEEK_SET);     # reset filehandle to beginning of file
			while (<$response_body>) {
				$xml .= $_;
			}
		} else {
			print ("An error occured: ".$return_code." ".$curl->strerror($return_code)." ".$curl->errbuf." at getImageLink()\n");
		}
	}
	eval {
		$xmlDoc->parse($xml);
		my $xmlHash = $xmlDoc->toHash();
		$imageLink = $xmlHash->{'IMDBDocumentList'}->{'item'}->{'poster'};
		if(defined($imageLink)) {
			chomp($imageLink);
		} else {
			$imageLink = "";
		}
		my $imageFile = getLastFromURL($imageLink);
		if(defined($imageFile)) {
			chomp($imageFile);
		} else {
			$imageFile = "";
		}
		if(defined($imageLink) && ($imageLink ne "")) {
			unless (-e $webRoot . $coverCachePlacement . $imageFile) {getstore($imageLink, $webRoot . $coverCachePlacement . $imageFile);}
			return $imageLink;
		}
		return 0;
	} or do {
		return 0;
	}
}
sub getTrailer {
	#Called from html/table script only
	my $movieName = shift;
	my $videoNumber = shift;
	$videoNumber = "" if(!defined($videoNumber));
	$movieName = substr $movieName, $movieNameOffset;
	$movieName = nameProcessor(lc($movieName));
	my ($embedable, $movedURL);
	
	my $verifyTrailer = checkTrailerExistence($movieName);
	if (!$verifyTrailer && checkDBConnection()) {
		my $url = getGoogleTrailerURL($movieName);
		$movedURL = getGooglesNestedURL($url);
		if($movedURL) {$embedable = checkEmbedable($movedURL);} else {$embedable = 0; $movedURL="http://www.imdb.com";}
		if($embedable) {$movedURL =~ s/watch\?v=/embed\//i;}
		addTrailerUrl($movieName, $movedURL, $embedable);
	} else {
		($movedURL, $embedable) = getDBTrailerUrl($movieName);
	}
	if($embedable && !$neverEmbed) {
		return "<iframe id=\"movieTrailerFrame\" width=\"". ($rowFactor*190) ."\" height=\"". ($rowFactor*150) ."\" src=\"" . $movedURL . "\" frameborder=\"0\" allowfullscreen></iframe>";
	} else {
		#if($embedable) {
			$movedURL =~ s/embed\//watch\?v=/i;
			my $pictureName = getLastFromURL(checkUrlExistence($movieName));
			my $rand = round(rand(100));
			my $mid = substr($pictureName, 0, 14).$videoNumber.$rand;
			if( -e $webRoot . $coverCachePlacement . $pictureName) {
				return "<a href=\"" . $movedURL . "\" target=\"newWindow\" class=\"coverInsteadOfTrailerLink\"><img src=\"/" . $coverCachePlacement . $pictureName . "\" width=\"". ($rowFactor*190) ."\" height=\"". ($rowFactor*150) ."\" border=\"0\" class=\"coverInsteadOfTrailer\" id=\"".$mid."\" OnMouseOver=\"showZoomPlayButton('" . $pictureName . "', '".$mid."');\" /><span class=\"zoom-playButton\" id=\"".$mid."\"><img src=\"/" . $urlImagePlacement . "playButton.png\" width=\"". ($rowFactor*190) ."\" height=\"". ($rowFactor*150) ."\" alt=\"Zoom\" OnMouseOut=\"hideZoomPlayButton('" . $pictureName . "', '".$mid."');\" /></span></a>".$cgi->span({-class=>'trailerText', -id=>$mid},"Trailer");
			}			
		#}
		return "<a href=\"" . $movedURL . "\" target=\"newWindow\"><img src=\"/" . $urlImagePlacement . "playButton.png" . "\" width=\"". ($rowFactor*190) ."\" height=\"". ($rowFactor*150) ."\" border=\"0\" id=\"playButtonInsteadOfTrailer\" /></a>";
	}
}
sub getMovieCover {
	#Called from within HTML Section
	my $movieName = shift;
	$movieName = substr $movieName, $movieNameOffset;
	$movieName = nameProcessor(lc($movieName));
	my $verifyUrl = getLastFromURL(checkUrlExistence($movieName));
	if (!$verifyUrl && checkDBConnection()) {
		my $movieCover = initiateMovieCover($movieName);		
		return ($movieCover ? $movieCover : "<img src=\"/". $urlImagePlacement . "whitequestionmark.png\" width=\"". ($rowFactor*97) ."\" height=\"". ($rowFactor*125) ."\" alt=\"API error\" name=\"imgImageCover\" />");
	} else {
		#1. Get URL from database
		my $imageLink = $verifyUrl;
		if(!$imageLink) { return "<img src=\"/". $urlImagePlacement . "warning.png\" width=\"". ($rowFactor*97) ."\" height=\"". ($rowFactor*125) ."\" alt=\"Cover Not Found\" name=\"imgImageCover\" />"; }
		my $pictureName = getLastFromURL($imageLink);
		if( -e $webRoot . $coverCachePlacement . $pictureName && checkDBConnection()) {
			#checkAndGetMovieRatingInDB($movieName);
			return "<a href=\"/". $coverCachePlacement . $pictureName ."\" rel=\"lightbox\" title=\"". $movieName ."\"><img src=\"/" . $coverCachePlacement . $pictureName . "\" width=\"". ($rowFactor*89) ."\" height=\"". ($rowFactor*157) ."\" border=\"0\" alt=\"". $movieName ."\" name=\"imgImageCover\" /></a>";
		} else {
			my $movieCover = initiateMovieCover($movieName);
			return ($movieCover ? $movieCover : "<img src=\"/". $urlImagePlacement . "whitequestionmark.png\" width=\"". ($rowFactor*97) ."\" height=\"". ($rowFactor*125) ."\" alt=\"API error\" name=\"imgImageCover\" />");
		}
	}
}
sub setTrailerToDB {
	my $movieName = shift;
	my ($embedable, $movedURL);
	$movieName = nameProcessor(lc($movieName));
	my $verifyTrailer = checkTrailerExistence($movieName);
	if (!$verifyTrailer && checkDBConnection()) {
		my $url = getGoogleTrailerURL($movieName);
		$movedURL = getGooglesNestedURL($url);
		#Check that url is valid before we continue:
		if($movedURL =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|) {
			if($movedURL) {$embedable = checkEmbedable($movedURL);} else {$embedable = 0; $movedURL="http://www.imdb.com";}
			if($embedable) {$movedURL =~ s/watch\?v=/embed\//i;}
			chomp($movedURL);
			addTrailerUrl($movieName, $movedURL, $embedable);
		}
	} 
}
sub checkEmbedable {
	my $url = shift;
	if(!$url) {return 0;}
	if($url =~ /Sorry, Google is blocking us!/) {
		return 0;
	}
	my $embedable = 0;
	if($url =~ /http/) {
		my $response_body = tempfile();
		my $curl = WWW::Curl::Easy->new;

		$curl->setopt(CURLOPT_HEADER, 1);
		$curl->setopt(CURLOPT_URL, $url);
		$curl->setopt(CURLOPT_WRITEDATA, $response_body);

		my $return_code = $curl->perform;

		if ($return_code == 0) {
			my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
			seek($response_body, 0, SEEK_SET);     # reset filehandle to beginning of file
			while (<$response_body>) {
				if($_ =~ /$youtubeEmbedString/) {
					$embedable = 1;
				}
			}
		} else {
			print ("An error occured: ".$return_code." ".$curl->strerror($return_code)." ".$curl->errbuf." at checkEmbedable()\n");
		}
	}
	return $embedable;
}
sub checkFileEnding {
	my $nameField = shift;
	if(defined($nameField)) {
		return (($nameField =~ m/mpg$/i) || ($nameField =~ m/avi$/i) || ($nameField =~ m/mpeg$/i) || ($nameField =~ m/mkv$/i) || ($nameField =~ m/mp4$/i) || ($nameField =~ m/iso$/i) || ($nameField =~ m/rar\/$/i) || ($nameField =~ m/jar$/i) || ($nameField =~ m/img$/i));
	} else { return 0; }
}
sub returnFileType {
	my $nameField = shift;
	return substr($nameField, (length($nameField)-3), 3)
}
sub getRatingFromAPI {
	my $movieName = shift;
	my $processedMovieName = nameProcessor($movieName);
	my $searching = 1;
	my $rating;
	while($searching) {		
		#print "Called getRatingFromAPI for " . nameProcessor($processedMovieName) . "<br/>";
		my $url = "http://mymovieapi.com/?title=".uri_escape($processedMovieName)."&type=xml&plot=none&episode=1&limit=1&yg=0&mt=none&lang=en-US&offset=&aka=simple&release=simple&business=0&tech=0";
		my $xmlDoc = XML::Mini::Document->new();
		my $xml;
		my $lastReturnCode = 0;
		if($url =~ /http/) {
			my $response_body = tempfile();
			my $curl = WWW::Curl::Easy->new;

			$curl->setopt(CURLOPT_HEADER, 1);
			$curl->setopt(CURLOPT_URL, $url);
			$curl->setopt(CURLOPT_WRITEDATA, $response_body);

			my $return_code = $curl->perform;
			my $getNextLine = 0;
			if ($return_code == 0) {
				my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
				seek($response_body, 0, SEEK_SET);     # reset filehandle to beginning of file
				while (<$response_body>) {
					$xml .= $_;
				}
				$searching = 0;
			} elsif($return_code == 56 && $lastReturnCode != 56) {
				#If we were interupted, we try to search one more time.
				#print "We were interrupted, we are trying again<br/>";
				$searching = 1;
				$lastReturnCode = $return_code;
			} else {
				print ("An error occured: ".$return_code." ".$curl->strerror($return_code)." ".$curl->errbuf." at getRatingFromAPI() when trying to fetch " . nameProcessor($movieName). " \n");
				$searching = 0;
			}
		}
		$xmlDoc->parse($xml);
		my $xmlHash = $xmlDoc->toHash();
		$rating = $xmlHash->{'IMDBDocumentList'}->{'item'}->{'rating'};
		if(defined($rating)) {undef($rating) if($rating eq "");}
		
		#If movie name does not end as a single word in 4 digits, we consider searching as done:
		if($processedMovieName !~ m/\b\d{4}\b$/){$searching = 0;}
		#If movie name does end as a single word in 1 to 4 digits and rating is not defined, we remove those last 1 to 4 digits:
		if($processedMovieName =~ m/\b\d{1,4}\b$/ && !defined($rating)){$processedMovieName =~ s/\b\d{1,4}\b$//;}
		#If we have a rating, we are done -  specify this just to be safe:
		if(defined($rating) && ($rating ne "")) {$searching = 0;}		
	}
	if(!defined($rating)) { return 0;}
	return $rating;
}
sub intCheck{
	my $num = shift;
	return ($num =~ m/^\d+$/);
}
sub round {
	my $var = shift;
	if (intCheck($var - 0.5)) { $var = $var + 0.1; }
	return ceil($var);
}
sub getFilteredVideoName {
	#Called from html/table script only
	my $movieName = shift;
	$movieName = substr $movieName, $movieNameOffset;
	$movieName = nameProcessor(lc($movieName));
	chomp($movieName);
	$movieName =~ s/[^\w]//g;
	return $movieName;
}
sub refreshTrailerURL {
	my $movieName = shift;
	$movieName = nameProcessor(lc($movieName));
	my $url = getGoogleTrailerURL($movieName);
	my $movedURL = getGooglesNestedURL($url);
	my $embedable = checkEmbedable($movedURL);
	if($embedable) {$movedURL =~ s/watch\?v=/embed\//i;}
	addTrailerUrl($movieName, $movedURL, $embedable);
}
sub checkTrailingSlash {
	my $nameCheck = shift;
	$nameCheck  = $nameCheck  . '/' if($nameCheck  !~ m/\/$/i);
	return $nameCheck;
}
sub getLastFromURL {
	my $url = shift;
	if(defined($url) && ($url ne "")) {
		my @split = split("/",$url);
		return $split[(scalar @split) - 1];
	}
	return "";
}
sub getAllMovieSpecs {
	my $movieFile = shift;
	my $whereis = `whereis -b ffmpeg`;
	my @whereisSplit = split(' ', $whereis);
	if((scalar @whereisSplit) < 2) { return "N/A"; }
	my $ffmpeg = $whereisSplit[1];
	my %videoInfo = videoInfo($ffmpeg, $movieFile);
	return %videoInfo;
}
sub videoInfo {
	#Thanks to http://www.andrewault.net/2010/07/09/perl-script-to-get-video-details/ for sharing his code
	my $ffmpeg = shift;
	my %finfo = (
		'duration'		=> "00:00:00.00",
		'bitrate'		=> "0",
		'vcodec'		=> "",
		'vformat'		=> "",
		'resolution'	=> "",
		'acodec'		=> "",
		'asamplerate'	=> "0",
		'achannels'		=> "0",
	);
	my $file = shift;
	# escaping characters
	$file =~ s/(\W)/\\$1/g;
	open3( "</dev/null", ">/dev/null", \*ERPH, "$ffmpeg -i $file" ) or die "can't run $ffmpeg\n";
	my @res = <ERPH>;
	# parse ffmpeg output
	foreach (@res) {
		# duration
		if ($_ =~ /Duration:/) {
			$finfo{'duration'} = substr($_, 12, 10);
		}
		# bitrate
		if ($_ =~ /bitrate: (\d*) kb\/s/) {
			$finfo{'bitrate'} = $1;
		}
		# vcodec and vformat
		if ($_ =~ /Video: (\w*), (\w*), (\w*) \[/) {
			$finfo{'vcodec'}  = $1;
			$finfo{'vformat'} = $2;
			$finfo{'resolution'} = $3;
		}
		# Stream #0.1(und): Audio: aac, 48000 Hz, 1 channels, s16, 64 kb/s
		# acodec, samplerate, stereo and audiorate
		if ($_ =~ /Audio: (\w*), (\d*) Hz, (\d*)/) {
			$finfo{'acodec'}     = $1;
			$finfo{'asamplerate'} = $2;
			$finfo{'achannels'} = $3;
		}
	}
	close(ERPH) or die "Can't close filehandle! $!";
	return %finfo;
}
sub checkSamba {
	if($sambaProcStatus == 1 || $sambaProcStatus == 0){
		return $sambaProcStatus;
	} else {
		my @smbds =  `ps aux | grep smbd`;
		if(scalar @smbds > 2) {
			$sambaProcStatus = 1;
			return $sambaProcStatus;
		} else {
			$sambaProcStatus = 0;
			return $sambaProcStatus;
		}
	}
}
sub isShared {
	if($isShared == 1 || $isShared == 0) {
		return $isShared;
	} else {
		my $sambaConf;
		my $samba =  `whereis samba`;
		my @sambaSplit = split(' ', $samba);
		my $searcString = substr($moviePlacement, 0, length($moviePlacement)-1);
		foreach(@sambaSplit) {
			if($_ =~ /\/etc/) {
				$sambaConf = $_ . "/smb.conf";
			}
		}
		open(sambaConf, $sambaConf);
		while(<sambaConf>) {
			if($_ =~ m/path = ($searcString)/) {
				$isShared = 1;
				return $isShared;
			}
		}
		close(sambaConf);
		$isShared = 0;
		return $isShared;
	}
}
sub checkSambaUsage {
	if(lc($sambaUsage) eq "on") {return 1;}
	if(lc($sambaUsage) eq "off") {return 0;}
}
sub getIMFDBLink {
	my $movieName = shift;
	$movieName = substr $movieName, $movieNameOffset;
	return $cgi->a({-href=>'http://www.imfdb.org/wiki/' . underscoreSpace(nameProcessor($movieName)), -target=>"_blank", -class=>'suggestionLinks'.$linkRevisor}, "<img src=\"/".$urlImagePlacement."logoimfdb.png\" width=\"".($rowFactor*24)."\" height=\"".($rowFactor*24)."\" BORDER=\"0\" title=\"Find it at the Internet Movie Firearms Database\" />");
}
sub getIMDBLink {
	my $movieName = shift;
	my $imdbUrl = getDBIMDBUrl(nameProcessor($movieName));
	return $cgi->a({-href=> $imdbUrl eq "N/A" ? 'http://www.imdb.com' : $imdbUrl, -target=>"_blank", -class=>'suggestionLinks'.$linkRevisor}, "<img src=\"/".$urlImagePlacement."logoIMDB.png\" width=\"".($rowFactor*24)."\" height=\"".($rowFactor*24)."\" BORDER=\"0\" title=\"Find it at IMDB\" />");
}
sub getNFOOGLELink {
	return $cgi->a({-href=>'http://nfoogle.com/', -target=>"_blank", -class=>'suggestionLinks'.$linkRevisor}, "<img src=\"/".$urlImagePlacement."logonfoogle.gif\" width=\"".($rowFactor*24)."\" height=\"".($rowFactor*24)."\" BORDER=\"0\" title=\"Search for subtitles\" />");
}
sub getICMDBLink {
	my $movieName = shift;
	$movieName = substr $movieName, $movieNameOffset;
	return $cgi->a({-href=>'http://www.google.com/search?hl=en&q=imcdb+' . uri_escape(nameProcessor($movieName)) . '&btnI=I%27m+Feeling+Lucky', -target=>"_blank", -class=>'suggestionLinks'.$linkRevisor}, "<img src=\"/".$urlImagePlacement."logoIMCDB.png\" width=\"".($rowFactor*24)."\" height=\"".($rowFactor*24)."\" BORDER=\"0\" title=\"Find it at the Internet Movie Car Database\" />");
}
sub getTMDBLink {
	my $movieName = shift;
	$movieName = substr $movieName, $movieNameOffset;
	return $cgi->a({-href=>'http://www.themoviedb.org/search?search=' . uri_escape(nameProcessor($movieName)), -target=>"_blank", -class=>'suggestionLinks'.$linkRevisor}, "<img src=\"/".$urlImagePlacement."logoTMDb.png\" width=\"".($rowFactor*24)."\" height=\"".($rowFactor*24)."\" BORDER=\"0\" title=\"Find it at TheMovieDB.org\" />");
}
sub getTasteListLink {
	my $movieName = shift;
	$movieName = substr $movieName, $movieNameOffset;
	return $cgi->a({-href=>'http://www.tastekid.com/like/' . uri_escape(nameProcessor($movieName)) . '/movies', -target=>"_blank", -class=>'suggestionLinks'.$linkRevisor}, "<img src=\"/".$urlImagePlacement."logoTasteKid.png\" width=\"".($rowFactor*24)."\" height=\"".($rowFactor*24)."\" BORDER=\"0\" title=\"Check it out at TasteList.com\" />");
}
sub getReloadLink {
	my $movieName = shift;
	my $rowID = shift;
	$movieName = substr $movieName, $movieNameOffset;
	return "<img src=\"/".$urlImagePlacement."reloadMovie.png\" width=\"".($rowFactor*24)."\" height=\"".($rowFactor*24)."\" title=\"Mark movie for reload from the internet\" id=\"reloadMovieButton-".$rowID."\" OnClick=\"toggleMovieRefresh('".$rowID."','".$movieName."','".$urlImagePlacement."');\" />";
}
sub underscoreSpace {
	my $string = shift;
	my @splitString = split(" ", $string);
	$string = "";
	foreach(@splitString) {
		$string .= $_."_";
	}
	chop($string);
	return $string;
}
sub initiateFileInfo {
	##This sub is the main collector of data about the files that the movies consist of. 
	##If data is not found in DB, this sub is called to collect it all.
	my $movieName = shift;
	$movieName = substr $movieName, $movieNameOffset;
	$movieName = nameProcessor(lc($movieName));
	my $filename = shift;
	my %videoInfo;
	#print "F-1 " . $filename . "<br/>";
	if(defined($filename)) {
		if(!checkMovieFileSearched($filename)) {
			if(!checkBitRateIsDBSet($movieName, $filename) || !checkResolutionIsDBSet($movieName, $filename) || !checkDurationIsDBSet($movieName, $filename)) {
				%videoInfo = getAllMovieSpecs($filename);
			}
			if(!checkBitRateIsDBSet($movieName, $filename)) {
				setBitRateDB($movieName, $videoInfo{'bitrate'}, $filename);
			}
			if(!checkResolutionIsDBSet($movieName, $filename)) {
				setResolutionDB($movieName, $videoInfo{'resolution'}, $filename);
			}
			if(!checkDurationIsDBSet($movieName, $filename)) {
				setDurationDB($movieName, $videoInfo{'duration'}, $filename);
			}
			setMovieFileSearched($filename);
		}
	}
}
sub getNoMoviesFromDisk {
	my $dir = shift;
	my @files = <$dir*>;
	return scalar @files;
}
sub getMovieNameOffset {
	return $movieNameOffset;
}
sub getCGIObj {
	return $cgi;
}
sub getMoviePlacement {
	return $moviePlacement;
}
sub getUrlImagePlacement {
	return $urlImagePlacement;
}
sub getUrlMoviePlacement {
	return $urlMoviePlacement;
}
sub getMainScriptName {
	my @scriptSplit = split('/',$0);
	return $scriptSplit[scalar @scriptSplit-1];
}
sub getTableType {
	return $tableType;
}
sub getPageValue {
	return $value;
}
sub getDbUser {
	return $dbUser;
}
sub getDbPassword {
	return $dbPassword;
}
sub getConfigFile {
	return $configFile;
}
sub getNumberOfRecomendations {
	return $numberOfRecomendations;
}
sub getUpdateInterval {
	return $updateInterval;
}
sub getLinkRevisor {
	return $linkRevisor;
}
#Used when testing:
#open FH, ">>/tmp/log.log" or die "can't open '/tmp/log.log': $!";
#print FH $dbFilmDiskPath . "\n";
#close FH;

#Functions not used anymore, but who are saved heer for some time just in case:
#sub getDBMovieURL {
#	my $movieName = shift;
#	my ($dbh, $result);
#
#	$dbh=DBI->connect('dbi:mysql:movie_info_db',$dbUser,$dbPassword,{AutoCommit => 0}) || die "Error opening database: $DBI::errstr\n";
#	$result = $result->[0]->[0];
#	$dbh->disconnect || die "Failed to disconnect\n";
#	return $result;
#}
1;