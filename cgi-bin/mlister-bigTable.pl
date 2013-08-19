#!/usr/bin/perl -w
#Creator: Atle Holm - atle@team-holm.net

use CGI;
use strict;
use CGI::Pretty;
use CGI::Carp qw/fatalsToBrowser warningsToBrowser/;
use Socket 'inet_ntoa';
use Sys::Hostname 'hostname';
my $cgi=new CGI;
my $addr = inet_ntoa(scalar gethostbyname(hostname() || 'localhost'));
my $urlImagePlacement = getUrlImagePlacement();
my $urlMoviePlacement = getUrlMoviePlacement();
my $mainScriptName = getMainScriptName();

sub createHTMLTable {
	my $movieContainer_r = shift;
	my @movieContainer = @$movieContainer_r;
	my $moviePlacement_r = shift;
	my $moviePlacement = $$moviePlacement_r;
	my $urlMoviePlacement_r = shift;
	$urlMoviePlacement = $$urlMoviePlacement_r;
	my $currentPagePosition_r = shift;
	my $currentPagePosition = $$currentPagePosition_r;
	my $currentMoviesPerPage_r = shift;
	my $currentMoviesPerPage = $$currentMoviesPerPage_r;
	my $sampleSizeLimit = 100994432;

	print "<table border=\"0\" align=\"center\" bgcolor=\"white\" cellspacing=\"0\" width=\"100%\" id=\"theMovieListerTable\">";
	print "<!-- big table -->\n";
	print "<tr><th>Title</th><th>Cover</th><th>Trailer</th></tr>";
	my $lightColor = 0;
	my $lastMovieName = "";
	
	for (my $filePosition = $currentPagePosition; $filePosition <= ($currentPagePosition + $currentMoviesPerPage); $filePosition ++) {	
		my $filmFolder = $movieContainer[$filePosition];
		my @videoNameSplit;
		my @videoContent;
		my @videoFile;

		if ($filmFolder) {
			@videoNameSplit =  split('/', $filmFolder);
			if(checkPathForFilesInCache($filmFolder)) {
				getVideoContentDB(\@videoContent, $filmFolder);
			} else {
				@videoContent = `ls "$filmFolder"`;
			}
		} else {
			next;
		}
		my $videoName = $videoNameSplit[(scalar @videoNameSplit) - 1];
		my $lastField = $videoNameSplit[(scalar @videoNameSplit) - 1];
		
		if(defined($videoName) && $videoName ne "." && $videoName ne "..") {
			my @sampleVideos;
			foreach my $file (@videoContent) {
				if (checkFileEnding($file)) {
					chomp($file);
					my $filename;
					#If $file starts with / then it is a standalone file not in its own folderm the path to it is ready already:
					if(substr($file, 0, 1) eq '/') {$filename = $file;}else{ $filename = $filmFolder. "/" .$file;}
					my $size = -s $filename;
					if ($size < $sampleSizeLimit && $size != 0) {
						push(@sampleVideos, $file);
					} elsif($size => $sampleSizeLimit && $size != 0) {
						push(@videoFile, $file);
					}
				}
			}
			foreach my $file (@sampleVideos) {
				push(@videoFile, $file);
			}
			my $X = 0;
			foreach my $vid (@videoFile) { 
				$X ++;
				my $filename;
				my $linkContent;
				#We check if the last field is a movie file, or a folder name and set variables accordingly:
				if(checkFileEnding($lastField)) {
					$filename = $moviePlacement . $lastField;
					$linkContent = $urlMoviePlacement . $lastField;
					$videoName = nameProcessor($videoName);
				} else {
					$filename = $moviePlacement . $lastField . "/$vid";
					$linkContent = $urlMoviePlacement . $lastField . "/$vid";
				}
				chomp($filename);
				my $size = -s $filename;
				if ($lightColor == 0) {
					if ($size < $sampleSizeLimit) {
						initiateFileInfo($videoName, $filename);
						sampleMovieRow($videoName, $filename, $linkContent, 'Beige', 'movieLinks-red');
						$X --;
					} else {
						initiateMovieInfo($videoName);
						initiateFileInfo($videoName, $filename);
						if($X < 2 || ((scalar @videoFile) == 2)) {
							fullMovieRow($videoName, $filename, $linkContent, 'Beige', 'movieLinks-red', $size, $filePosition, $X);
							$lastMovieName = $videoName;
						} else {
							#If there are more than two files belonging to one movie name:
							minimalMovieRow($videoName, $linkContent, 'Beige', 'movieLinks-red', $X);
						}
					}
					$lightColor = 1;
				} else {
					if ($size < $sampleSizeLimit) {
						initiateFileInfo($videoName, $filename);
						sampleMovieRow($videoName, $filename, $linkContent, 'Azure', 'movieLinks-black');
						$X --;
					} else {
						initiateMovieInfo($videoName);
						initiateFileInfo($videoName, $filename);
						if($X < 2 || ((scalar @videoFile) == 2)) {
							fullMovieRow($videoName, $filename, $linkContent, 'Azure', 'movieLinks-black', $size, $filePosition, $X);
							$lastMovieName = $videoName;
						} else {
							#If there are more than two files belonging to one movie name:
							minimalMovieRow($videoName, $linkContent, 'Azure', 'movieLinks-black', $X);
						}
					}
					$lightColor = 0;
				}
			}
		}
	}
	print "<tr id=\"hiddenDummyRow\" style=\"display:none;\"><td></td><td></td><td></td></tr>"; # Dummy row before the last row so that we can insert rows before this one without trouble
	print "<tr id=\"addingRowRow\"><td bgcolor=\"".($lightColor ? "Azure" : "Beige")."\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"".($lightColor ? "Azure" : "Beige")."\"></td><td bgcolor=\"".($lightColor ? "Azure" : "Beige")."\"><img src=\"/".$urlImagePlacement."addMovieButton.gif\" id=\"addMovieButton\" title=\"Add a movie to this list from the next page\" alt=\"Add a movie to this list from the next page\" onClick=\"addMovieRow('".$lastMovieName."','".$mainScriptName."')\"/></td></tr>";
	print "</table>";
	print "<span id=\"lastRowColorSpan\" style=\"display:none;\">".($lightColor ? "Beige" : "Azure")."</span>";
	print "<div id=\"footer_message\" onMouseOut=\"document.getElementById('footer_message').style.visibility='hidden';\" align=\"center\">Stay on Bottom of the Page</div>";
}
1;
sub fullMovieRow {
	my $videoName = shift;
	my $filename = shift;
	my $linkContent = shift;
	my $rowColor = shift;
	my $linkStyle = shift;
	my $size = shift;
	my $filePosition = shift;
	my $X = shift;
	my $rowID = getMovieIDByMovieName($videoName);
	my $displayName = nameProcessorWithOffset($videoName);
	
	print "<tr id=\"".$rowID."-".$X."\"><td valign=\"top\" OnMouseOver=\"this.style.backgroundColor='Silver';document.getElementById('div-$filePosition-$X').className='whiteBorder';document.getElementById('divB-$filePosition-$X').className='whiteBorder';document.getElementById('divC-$filePosition-$X').className='whiteBorder';\" OnMouseOut=\"this.style.backgroundColor='". $rowColor ."';document.getElementById('div-$filePosition-$X').className='greyBorder';document.getElementById('divB-$filePosition-$X').className='greyBorder';document.getElementById('divC-$filePosition-$X').className='greyBorder';\" bgcolor=\"". $rowColor ."\" width=\"*\">";
		print "<table border=\"0\" align=\"center\" cellspacing=\"0\" width=\"100%\">";
		print "<tr><td colspan=\"2\">";
		print getRightFolderLink("large");
		print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" . $cgi->a({-href=>"/" . $linkContent, -class=>$linkStyle, -OnMouseOver=>'showSimplePlot(\''.$rowID.'-'.$X.'\',\''.$mainScriptName.'\');', -OnMouseOut=>'jQuery(\'#plotMessageBox\').fadeOut();'}, $displayName . "- Video " . $X) . "<span id=\"name-".$rowID."-".$X."\" style=\"visibility:hidden;\">".$displayName."</span></td>";
		print "<td><i>Rated:</i><span id=\"ratingContainer\"> " . getDBMovieRating($videoName) . "</span></td></tr>";
		print "<tr><td width=\"40%\"><div id=\"div-$filePosition-$X\" class=\"greyBorder\"><table border=\"0\" height=\"113\"><tr><td valign=\"top\"><b class=\"smallBoxHeader\">Details:</b><br/><b>Genre:</b><span id=\"genreContainer\"> " . getDBMovieGenre($videoName) . "</span><br/><b>Filesize:</b> " . getSize($size) . "<br/><b>Bitrate:</b><span id=\"bitrateContainer\"> " . getBitRateDB($videoName, $filename) . " </span>kb/s</td><td valign=\"top\"><br/><b>Quality:</b><span id=\"qualityContainer\"> " . getResolutionDB($videoName, $filename) . "</span><br/><b>Filetype:</b> " . returnFileType($filename) . "<br/><b>Duration:</b><span id=\"durationContainer\"> " . getDurationDB($videoName, $filename) . " </span></td></tr></table></div></td>";
		print "<td width=\"24%\"><div id=\"divB-$filePosition-$X\" class=\"greyBorder\"><table border=\"0\" height=\"113\"><tr><td valign=\"top\"><b class=\"smallBoxHeader\">Recomendations:</b></td></tr><tr><td valign=\"top\"><span id=\"suggestionContainer\">".getDBSuggestions($videoName)."</span></td></tr></table></div></td>";
		print "<td width=\"36%\"><div id=\"divC-$filePosition-$X\" class=\"greyBorder\"><table border=\"0\" height=\"113\"><tr><td><table border=\"0\"><tr><td valign=\"top\"><b class=\"smallBoxHeader\">Suggestions:</b></td></tr><tr><td valign=\"top\">".getIMFDBLink($videoName).getIMDBLink($videoName)."<br/>".getICMDBLink($videoName).getTMDBLink($videoName)."<br/>".getNFOOGLELink().getTasteListLink($videoName)."</td></tr></table></td><td width=\"100%\"><table style=\"float:right; margin: 0 0 74px 0px;\" border=\"0\"><tr><td><span id=\"forceStatus-".$rowID."-".$X."\" style=\"display:none;\">noForcedReload</span></td></tr><tr><td style=\"cursor: pointer;\" OnClick=\"toggleMovieRefresh('".$rowID."-".$X."');\">".getReloadLink()."</td></tr></table></td></table></div></td>";
		print "</tr>";					
		print "</table>";
	print "<td width=\"97\" height=\"125\" align=\"center\" bgcolor=\"". $rowColor ."\" id=\"coverCell\"><span id=\"coverContainer\">" . getMovieCover($videoName) . "</span></td>";
	print "<td width=\"190\" height=\"150\" align=\"center\" bgcolor=\"". $rowColor ."\" id=\"trailerCell\"><span id=\"trailerContainer\">" . getTrailer($videoName, $X) . "</span></td>";
	print "</tr>";
}
sub minimalMovieRow {
	my $videoName = shift;
	my $linkContent = shift;
	my $rowColor = shift;
	my $linkStyle = shift;
	my $X = shift;
	my $rowID = getMovieIDByMovieName($videoName);
	my $displayName = nameProcessorWithOffset($videoName);
	
	print "<tr id=\"".$rowID."-".$X."\"><td valign=\"top\" OnMouseOver=\"this.style.backgroundColor='Silver';\" OnMouseOut=\"this.style.backgroundColor='". $rowColor ."';\" bgcolor=\"". $rowColor ."\" width=\"*\">";
		print "<table border=\"0\" align=\"center\" cellspacing=\"0\" width=\"100%\">";
		print "<tr><td><!--- ---></td><td>";
		print getRightFolderLink("small");
		print "&nbsp;&nbsp;&nbsp;" . $cgi->a({-href=>"/" . $linkContent, -class=>$linkStyle.'-small'}, $displayName . "- Video " . $X) . "<span id=\"name-".$rowID."-".$X."\" style=\"visibility:hidden;\">".$displayName."</span></td>";
		print "<td><i>Rated:</i> See above</td></tr>";
		print "<tr><td width=\"47\"><!--- ---></td>";
		print "<td width=\"*\"><!--- ---></td>";
		print "<td width=\"34%\"><!--- ---></td>";
		print "</tr>";					
		print "</table>";
	print "<td width=\"97\" height=\"50\" align=\"center\" bgcolor=\"". $rowColor ."\"></td>";
	print "<td width=\"190\" height=\"50\" align=\"center\" bgcolor=\"". $rowColor ."\"></td>";
	print "</tr>";
}
sub sampleMovieRow {
	my $videoName = shift;
	my $filename = shift;
	my $linkContent = shift;
	my $rowColor = shift;
	my $linkStyle = shift;
	my $rowID = getMovieIDByMovieName($videoName)."-".getFilteredVideoName($filename);
	my $displayName = nameProcessorWithOffset($videoName);
	
	print "<tr id=\"".$rowID."-sample\"><td valign=\"top\" OnMouseOver=\"this.style.backgroundColor='Silver';\" OnMouseOut=\"this.style.backgroundColor='". $rowColor ."';\" bgcolor=\"". $rowColor ."\" width=\"*\">";
		print "<table border=\"0\" align=\"center\" cellspacing=\"0\" width=\"100%\">";
		print "<tr><td><!--- ---></td><td>";
		print getRightFolderLink("small");
		print "&nbsp;&nbsp;&nbsp;" . $cgi->a({-href=>"/" . $linkContent, -class=>$linkStyle.'-small'}, $displayName . "- Sample") . "<span id=\"name-".$rowID."-sample\" style=\"visibility:hidden;\">".$displayName."</span></td>";
		print "<td><i>Duration:</i> " . getDurationDB($videoName, $filename) . " </td></tr>";
		print "<tr><td width=\"47\"><!--- ---></td>";
		print "<td width=\"*\"><!--- ---></td>";
		print "<td width=\"34%\"><!--- ---></td>";
		print "</tr>";					
		print "</table>";
	print "<td width=\"97\" height=\"50\" align=\"center\" bgcolor=\"". $rowColor ."\"></td>";
	print "<td width=\"190\" height=\"50\" align=\"center\" bgcolor=\"". $rowColor ."\"></td>";
	print "</tr>";
}
sub getRightFolderLink {
	my $size = shift;
	if($size eq "small") {$size = "-".$size;}
	else {$size = "";}
	if(checkSambaUsage()) {
		if(!checkSamba()) {
			return $cgi->a({-href=>'/'.$urlImagePlacement.'penguin.jpg', -class=>'getFilePath'.$size, -rel=>'lightbox', title=>'Samba does not exist or is not running'}, "A");
		} else {
			if(isShared()) {
				return $cgi->a({-href=>'file://///'.$addr.'/'.$urlMoviePlacement, -class=>'getFilePath'.$size, -target=>"_blank", -onMouseOver=>'document.getElementById(\'footer_message\').style.visibility="visible";document.getElementById(\'footer_message\').innerHTML = "file://///'.$addr.'/'.$urlMoviePlacement.'";'}, "A");
			} else {
				return $cgi->a({-href=>'/'.$urlImagePlacement.'penguin.jpg', -class=>'getFilePath'.$size, -rel=>'lightbox', title=>'Fault: \'moviePlacement\' specified in the config file is not shared with Samba'}, "A");
			}
		}
	} else {
		return $cgi->a({-href=>'/'.$urlMoviePlacement, -class=>'getFilePath'.$size, -target=>"_blank"}, "A");
	}
}
sub getSize {
	my $size = shift;
	if(($size/1024) > 10240) {
		return round((($size/1024)/1024)) . " MB";
	} else {
		return round(($size/1024)) . " KB";
	}
}