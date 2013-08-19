#!/usr/bin/perl -w
#Creator: Atle Holm - atle@team-holm.net
use strict;

my $cgi = getCGIObj();
my $urlMoviePlacement = getUrlMoviePlacement();
my $moviePlacement = getMoviePlacement();

sub writeErrorXMLToBrowser {
	my $errorMessage = shift;
	my $output = "";
	my $writer = XML::Writer->new(
		OUTPUT      => \$output,
		DATA_MODE   => 1,
		DATA_INDENT => 1,
		NEWLINES => 0
	);
	$writer->xmlDecl('UTF-8');
	$writer->startTag('error');
		$writer->characters($errorMessage);
	$writer->endTag('error');
	$writer->end();
	print $cgi->header('text/xml'), $output;
}
sub writeOKXMLToBrowser {
	my $message = shift;
	my $output = "";
	my $writer = XML::Writer->new(
		OUTPUT      => \$output,
		DATA_MODE   => 1,
		DATA_INDENT => 1,
		NEWLINES => 0
	);
	$writer->xmlDecl('UTF-8');
	$writer->startTag('allOK');
		$writer->characters($message);
	$writer->endTag('allOK');
	$writer->end();
	print $cgi->header('text/xml'), $output;
}
sub	writeRepositoriesXMLToBrowser {
	my @repos_response = shift;
	my @repos;	
	my $output = "";
	my $writer = XML::Writer->new(
		OUTPUT      => \$output,
		DATA_MODE   => 1,
		DATA_INDENT => 1,
		NEWLINES => 0
	);
	$writer->xmlDecl('UTF-8');
	if($repos_response[0][0]) {
		my $allRepos_r = $repos_response[0][1];
		@repos = @$allRepos_r;
		$writer->startTag('repositoryinfo');
		foreach my $repo (@repos) {
		$writer->startTag('config');
			$writer->startTag('confset');
			$writer->characters($repo->[1]);
			$writer->endTag('confset');
			$writer->startTag('confname');
			$writer->characters($repo->[0]);
			$writer->endTag('confname');
			$writer->startTag('comment');
			$writer->characters($repo->[3]);
			$writer->endTag('comment');
			$writer->startTag('state');
			$writer->characters($repo->[2]);
			$writer->endTag('state');
			$writer->startTag('validity');
			$writer->characters(-e $repo->[1] ? '1' : '0');
			$writer->endTag('validity');
		$writer->endTag('config');
		}
		$writer->endTag('repositoryinfo');
	} else {
		$writer->startTag('error');
		$writer->characters($repos_response[0][1]);
		$writer->endTag('error');
	}	
	$writer->end();
	print $cgi->header('text/xml'), $output;
}
sub	writeMainConfigsetXMLToBrowser {
	my $configset = "/usr/share/movieLister/setup/master-config.conf";
	my $output = "";
	my $writer = XML::Writer->new(
		OUTPUT      => \$output,
		DATA_MODE   => 1,
		DATA_INDENT => 1,
		NEWLINES => 0
	);
	$writer->xmlDecl('UTF-8');
	$writer->startTag('configinfo');
	if($configset && -e $configset) {
		my $configSource = ConfigReader::Simple->new($configset);
		
		#Configuration section, this sextions sets the defaults if they are not defined in the configuration file:
		my $dbUser = "None detected";
		my $dbPassword = "None detected";
		my $configDone = "None detected";
		
		
		#If the values exist in the config file, use them:
		if($configSource->get("dbUser")) { $dbUser = $configSource->get("dbUser"); }
		if($configSource->get("dbPassword")) { $dbPassword = $configSource->get("dbPassword"); }
		if($configSource->get("configDone")) { $configDone = $configSource->get("configDone"); }
							
		$writer->startTag('dbUser');
		$writer->characters($dbUser);
		$writer->endTag('dbUser');		
		$writer->startTag('dbPassword');
		$writer->characters($dbPassword);
		$writer->endTag('dbPassword');						
		$writer->startTag('configDone');
		$writer->characters($configDone);
		$writer->endTag('configDone');						
	} else {
		$writer->startTag('error');
		$writer->characters('Not able to read config file: "' . $configset . '"');
		$writer->endTag('error');
	}	
	$writer->endTag('configinfo');
	$writer->end();
	print $cgi->header('text/xml'), $output;
}
sub	writeWholeConfigsetXMLToBrowser {
	my $configset = shift;
	my $output = "";
	my $writer = XML::Writer->new(
		OUTPUT      => \$output,
		DATA_MODE   => 1,
		DATA_INDENT => 1,
		NEWLINES => 0
	);
	$writer->xmlDecl('UTF-8');
	$writer->startTag('configinfo');
	if($configset && -e $configset) {
		my $configSource = ConfigReader::Simple->new($configset);
		
		#Configuration section, this sextions sets the defaults if they are not defined in the configuration file:
		my $moviePlacement = "None detected";
		my $urlMoviePlacement = "None detected";
		my $urlImagePlacement = "None detected";
		my $coverCachePlacement = "None detected";
		my $webRoot = "/usr/share/";
		my $listHeading = "None detected";
		my $dbUser = "None detected";
		my $dbPassword = "None detected";
		my $currentPagePosition = "None detected";
		my $currentMoviesPerPage = "None detected"; #14 means 15 in this part of the script, 14 means 14 from the config file. See below.
		my $styleSheetPlacement = "None detected";
		my $movieNameOffset = "None detected"; #Set to 0 if the moviename starts at the first character in the folder name
		my $updateInterval = "None detected"; #7 days
		my $tableType = "medium"; #Size of table displaying the movies
		my $javaScriptPlacement = "None detected";
		my $sambaUsage = "None detected";
		my $numberOfRecomendations = "None detected";
		my $numberOfMoviesBeforeDBTakeOver = "None detected";
		my $rowFactor = "None detected";
		my $linkRevisor = "None detected";
		my $youtubeEmbedString = "None detected";
		my $tastekidString = "None detected";
		my $neverEmbed = "None detected";
		my $tasteKidF = "None detected";
		my $tasteKidK = "None detected";
		my $forcedTasteKidAPI = "None detected";
		
		#If the values exist in the config file, use them:
		if(defined($configSource->get("moviePlacement"))) { $moviePlacement = $configSource->get("moviePlacement"); }
		if(defined($configSource->get("urlMoviePlacement"))) { $urlMoviePlacement = $configSource->get("urlMoviePlacement"); }
		if(defined($configSource->get("urlImagePlacement"))) { $urlImagePlacement = $configSource->get("urlImagePlacement"); }
		if(defined($configSource->get("coverCachePlacement"))) { $coverCachePlacement = $configSource->get("coverCachePlacement"); }
		if(defined($configSource->get("listHeading"))) { $listHeading = $configSource->get("listHeading"); }
		if(defined($configSource->get("dbUser"))) { $dbUser = $configSource->get("dbUser"); }
		if(defined($configSource->get("dbPassword"))) { $dbPassword = $configSource->get("dbPassword"); }
		if(defined($configSource->get("styleSheetPlacement"))) { $styleSheetPlacement = $configSource->get("styleSheetPlacement"); }
		if(defined($configSource->get("tableType"))) { $tableType = $configSource->get("tableType"); }
		if(defined($configSource->get("movieNameOffset")) && intCheck($configSource->get("currentMoviesPerPage"))) { $movieNameOffset = $configSource->get("movieNameOffset"); }
		if(defined($configSource->get("updateInterval")) && intCheck($configSource->get("currentMoviesPerPage"))) { $updateInterval = $configSource->get("updateInterval"); }
		if(defined($configSource->get("currentMoviesPerPage")) && intCheck($configSource->get("currentMoviesPerPage"))) { 
			$currentMoviesPerPage = $configSource->get("currentMoviesPerPage");
			$currentMoviesPerPage = ($currentMoviesPerPage - 1);
			if($currentMoviesPerPage < 0) { $currentMoviesPerPage = 0;} #means 1
		}
		if(defined($configSource->get("javaScriptPlacement"))) { $javaScriptPlacement = $configSource->get("javaScriptPlacement"); }
		if(defined($configSource->get("sambaUsage"))) { $sambaUsage = $configSource->get("sambaUsage"); }
		if(defined($configSource->get("numberOfRecomendations"))) { $numberOfRecomendations = $configSource->get("numberOfRecomendations"); }
		if(defined($configSource->get("numberOfMoviesBeforeDBTakeOver"))) { $numberOfMoviesBeforeDBTakeOver = $configSource->get("numberOfMoviesBeforeDBTakeOver"); }
		if(defined($configSource->get("youtubeEmbedString"))) { $youtubeEmbedString = $configSource->get("youtubeEmbedString"); }
		if(defined($configSource->get("tastekidString"))) { $tastekidString = $configSource->get("tastekidString"); }
		if(defined($configSource->get("neverEmbed"))) { $neverEmbed = $configSource->get("neverEmbed"); }
		if(defined($configSource->get("tasteKidF"))) { $tasteKidF = $configSource->get("tasteKidF"); }
		if(defined($configSource->get("tasteKidK"))) { $tasteKidK = $configSource->get("tasteKidK"); }
		if(defined($configSource->get("forcedTasteKidAPI"))) { $forcedTasteKidAPI = $configSource->get("forcedTasteKidAPI"); }
		
		$writer->startTag('moviePlacement');
		$writer->characters($cgi->escapeHTML($moviePlacement));
		$writer->endTag('moviePlacement');						
		$writer->startTag('urlMoviePlacement');
		$writer->characters($cgi->escapeHTML($urlMoviePlacement));
		$writer->endTag('urlMoviePlacement');						
		$writer->startTag('urlImagePlacement');
		$writer->characters($cgi->escapeHTML($urlImagePlacement));
		$writer->endTag('urlImagePlacement');						
		$writer->startTag('coverCachePlacement');
		$writer->characters($cgi->escapeHTML($coverCachePlacement));
		$writer->endTag('coverCachePlacement');						
		$writer->startTag('listHeading');
		$writer->characters($cgi->escapeHTML($listHeading));
		$writer->endTag('listHeading');						
		$writer->startTag('dbUser');
		$writer->characters($cgi->escapeHTML($dbUser));
		$writer->endTag('dbUser');		
		$writer->startTag('dbPassword');
		$writer->characters($cgi->escapeHTML($dbPassword));
		$writer->endTag('dbPassword');						
		$writer->startTag('styleSheetPlacement');
		$writer->characters($cgi->escapeHTML($styleSheetPlacement));
		$writer->endTag('styleSheetPlacement');						
		$writer->startTag('tableType');
		$writer->characters($cgi->escapeHTML($tableType));
		$writer->endTag('tableType');						;					
		$writer->startTag('movieNameOffset');
		$writer->characters($cgi->escapeHTML($movieNameOffset));
		$writer->endTag('movieNameOffset');		
		$writer->startTag('updateInterval');
		$writer->characters($cgi->escapeHTML($updateInterval));
		$writer->endTag('updateInterval');		
		$writer->startTag('javaScriptPlacement');
		$writer->characters($cgi->escapeHTML($javaScriptPlacement));
		$writer->endTag('javaScriptPlacement');		
		$writer->startTag('sambaUsage');
		$writer->characters($cgi->escapeHTML($sambaUsage));
		$writer->endTag('sambaUsage');		
		$writer->startTag('numberOfRecomendations');
		$writer->characters($cgi->escapeHTML($numberOfRecomendations));
		$writer->endTag('numberOfRecomendations');		
		$writer->startTag('numberOfMoviesBeforeDBTakeOver');
		$writer->characters($cgi->escapeHTML($numberOfMoviesBeforeDBTakeOver));
		$writer->endTag('numberOfMoviesBeforeDBTakeOver');
		$writer->startTag('youtubeEmbedString');
		$writer->characters($cgi->escapeHTML($youtubeEmbedString));
		$writer->endTag('youtubeEmbedString');	
		$writer->startTag('tastekidString');
		$writer->characters($cgi->escapeHTML($tastekidString));
		$writer->endTag('tastekidString');		
		$writer->startTag('neverEmbed');
		$writer->characters($cgi->escapeHTML($neverEmbed));
		$writer->endTag('neverEmbed');		
		$writer->startTag('tasteKidF');
		$writer->characters($cgi->escapeHTML($tasteKidF));
		$writer->endTag('tasteKidF');		
		$writer->startTag('tasteKidK');
		$writer->characters($cgi->escapeHTML($tasteKidK));
		$writer->endTag('tasteKidK');
		$writer->startTag('forcedTasteKidAPI');
		$writer->characters($forcedTasteKidAPI);
		$writer->endTag('forcedTasteKidAPI');		
	} else {
		$writer->startTag('error');
		$writer->characters('Not able to read config file: "' . $configset . '"');
		$writer->endTag('error');
	}	
	$writer->endTag('configinfo');
	$writer->end();
	print $cgi->header('text/xml'), $output;
}
sub writeMovieRowXMLToBrowser {
	my $lid = shift;
	my $lmovieName  = shift; 
	my $lmovieRating = shift; 
	my $lmovieGenre = shift; 
	my $lsuggestions = shift;
	my $lmovieCover = shift;
	my $lmovieTrailer = shift;
	my $lembedable = shift;
	my $limdbUrl = shift;
	my $output = "";
	$lid = "Obsolete" if(!defined($lid));
	$lmovieName = "Obsolete" if(!defined($lmovieName));
	$lmovieRating = "Obsolete" if(!defined($lmovieRating));
	$lmovieGenre = "Obsolete" if(!defined($lmovieGenre));
	$lsuggestions = "Obsolete" if(!defined($lsuggestions));
	$lmovieCover = "Obsolete" if(!defined($lmovieCover));
	$lmovieTrailer = "Obsolete" if(!defined($lmovieTrailer));
	$lembedable = "Obsolete" if(!defined($lembedable));
	$limdbUrl = "Obsolete" if(!defined($limdbUrl));
	my $writer = XML::Writer->new(
		OUTPUT      => \$output,
		DATA_MODE   => 1,
		DATA_INDENT => 1,
		NEWLINES => 0
	);
	$writer->xmlDecl('UTF-8');
	$writer->startTag('movieinfo');
		$writer->startTag('id');
		$writer->characters($lid);
		$writer->endTag('id');
		$writer->startTag('name');
		$writer->characters($lmovieName);
		$writer->endTag('name');
		$writer->startTag('rating');
		$writer->characters($lmovieRating);
		$writer->endTag('rating');
		$writer->startTag('genre');
		$writer->characters($lmovieGenre);
		$writer->endTag('genre');		
		$writer->startTag('cover');
		$writer->characters($lmovieCover);
		$writer->endTag('cover');
		$writer->startTag('suggestions');
		defined($lsuggestions) && $lsuggestions ne "" && length($lsuggestions) > 0 ? $writer->characters($lsuggestions) : $writer->characters("No suggestions found...");
		$writer->endTag('suggestions');
		$writer->startTag('trailer');
		$writer->characters($lmovieTrailer);
		$writer->endTag('trailer');
		$writer->startTag('embedable');
		$writer->characters($lembedable);
		$writer->endTag('embedable');
		$writer->startTag('imdbUrl');
		$writer->characters($limdbUrl);
		$writer->endTag('imdbUrl');
	$writer->endTag('movieinfo');
	$writer->end();
	print $cgi->header('text/xml'), $output;
}
sub writeConfigXMLToBrowser {
	my $lrowFactor = shift;
	my $lcoverCachePlacement = shift;
	my $llinkRevisor = shift;
	my $output = "";
	$lrowFactor = 1 if(!defined($lrowFactor));
	$lcoverCachePlacement = "coverCache/" if(!defined($lcoverCachePlacement));
	$llinkRevisor = "-medium" if(!defined($llinkRevisor));
	my $writer = XML::Writer->new(
		OUTPUT      => \$output,
		DATA_MODE   => 1,
		DATA_INDENT => 1,
		NEWLINES => 0
	);
	$writer->xmlDecl('UTF-8');
	$writer->startTag('configinfo');
		$writer->startTag('rowFactor');
		$writer->characters($lrowFactor);
		$writer->endTag('rowFactor');
		$writer->startTag('coverCachePlacement');
		$writer->characters($lcoverCachePlacement);
		$writer->endTag('coverCachePlacement');
		$writer->startTag('linkRevisor');
		$writer->characters($llinkRevisor);
		$writer->endTag('linkRevisor');
	$writer->endTag('configinfo');
	$writer->end();
	print $cgi->header('text/xml'), $output;
}
sub writePlotXMLToBrowser {
	my $simplePlotID = shift;
	my $output = "";
	$simplePlotID = 1 if(!defined($simplePlotID));
	my $plot = getDBPlotByID($simplePlotID);
	my $moviename = getMovieNameByID($simplePlotID);
	my $year = getDBProductionYearByID($simplePlotID);
	my $writer = XML::Writer->new(
		OUTPUT      => \$output,
		DATA_MODE   => 1,
		DATA_INDENT => 1,
		NEWLINES => 0
	);
	$writer->xmlDecl('UTF-8');
	$writer->startTag('plotinfo');
		$writer->startTag('moviename');
		$writer->characters($moviename);
		$writer->endTag('moviename');
		$writer->startTag('year');
		$writer->characters($year);
		$writer->endTag('year');
		$writer->startTag('plot');
		$writer->characters($plot);
		$writer->endTag('plot');
	$writer->endTag('plotinfo');
	$writer->end();
	print $cgi->header('text/xml'), $output;
}
sub writeNextMovieInfoWithXMLToBrowser {
	my $currentName = shift;
	my $lastRowColor = shift;
	my $output = "";
	$currentName = 0 if(!defined($currentName));
	$lastRowColor = 'Azure' if(!defined($lastRowColor));
	my $movieInfo_r = getNextMovieFromDB($currentName);
	my $writer = XML::Writer->new(
		OUTPUT      => \$output,
		DATA_MODE   => 1,
		DATA_INDENT => 1,
		NEWLINES => 0
	);
	if((intCheck($currentName) && $currentName == 0) || (intCheck($movieInfo_r) && $movieInfo_r == 0)) {
		$writer->xmlDecl('UTF-8');
		$writer->startTag('nextMovieInfo');
			$writer->startTag('error');
			$writer->characters('Requested movie \''.$currentName.'\' was not found, no row can be printed.');
			$writer->endTag('error');
		$writer->endTag('nextMovieInfo');
		$writer->end();
	} else {
		my $xmlMovieName;
		my $row;
		my $X = 0;
		local *STDOUT;
        open STDOUT, '>', \$row or die "Can't open STDOUT: $!";
		my @movieInfoArray = @$movieInfo_r;
		my $sampleSizeLimit = 100994432;
		my $lightColor = ($lastRowColor eq 'Azure' ? 0 : 1);
		for my $array_ref (@movieInfoArray) {
			$X ++;
			my $mName = $array_ref->[0];
			my $mPath = $array_ref->[1];
			my $mFile = $array_ref->[2];
			$xmlMovieName = $mName;
			my $size = -s checkTrailingSlash($mPath).$mFile;
			my @videoPathSplit =  split('/', $mPath);
			my $lastField = checkTrailingSlash($videoPathSplit[(scalar @videoPathSplit) - 1]);
			my $linkContent;
			my $filename;
			$urlMoviePlacement = checkTrailingSlash($urlMoviePlacement);
			if($urlMoviePlacement eq $lastField) {
				$filename = $moviePlacement.$mFile;
				$linkContent = $urlMoviePlacement.$mFile;
			} else {
				$filename = $moviePlacement.$lastField.$mFile;
				$linkContent = $urlMoviePlacement.$lastField.$mFile;
			}
			my $filePosition = "RowAddedByJavaScript" . (int(rand(1000)) + 1);
			if ($lightColor == 0) {
				if ($size < $sampleSizeLimit) {
						initiateFileInfo($mName, $filename);
						sampleMovieRow($mName, $filename, $linkContent, 'Beige', 'movieLinks-red');
						$X --;
					} else {
						initiateMovieInfo($mName);
						initiateFileInfo($mName, $filename);
						if($X < 2 || ((scalar @movieInfoArray) == 2)) {
							fullMovieRow($mName, $filename, $linkContent, 'Beige', 'movieLinks-red', $size, $filePosition, $X);
						} else {
							minimalMovieRow($mName, $linkContent, 'Beige', 'movieLinks-red', $X);
						}
					}
				$lightColor = 1;
			} else {
				if ($size < $sampleSizeLimit) {
					initiateFileInfo($mName, $filename);
					sampleMovieRow($mName, $filename, $linkContent, 'Azure', 'movieLinks-black');
					$X --;
				} else {
					initiateMovieInfo($mName);
					initiateFileInfo($mName, $filename);
					if($X < 2 || ((scalar @movieInfoArray) == 2)) {
						fullMovieRow($mName, $filename, $linkContent, 'Azure', 'movieLinks-black', $size, $filePosition, $X);
					} else {
						minimalMovieRow($mName, $linkContent, 'Azure', 'movieLinks-black', $X);
					}
				}
				$lightColor = 0;
			}
		}		
		$writer->xmlDecl('UTF-8');
		$writer->startTag('nextMovieInfo');
			$writer->startTag('name');
			$writer->characters($xmlMovieName);
			$writer->endTag('name');
			$writer->startTag('totalRows');
			$writer->characters((scalar @movieInfoArray));
			$writer->endTag('totalRows');
			$writer->startTag('row');
			$writer->characters("<![CDATA[" . $row . "]]");
			$writer->endTag('row');
		$writer->endTag('nextMovieInfo');
		$writer->end();
	}	
	print $cgi->header('text/xml'), $output;
}
1;