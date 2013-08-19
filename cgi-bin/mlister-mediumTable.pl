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
#my $tableType =  getTableType();

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
	print "<!-- medium table -->\n";
	print "<tr><th>Title</th><th>Cover</th><th>Trailer</th></tr>";
	my $lightColor = 0;
	my $lastMovieName = "";
	
	for (my $filePosition = $currentPagePosition; $filePosition <= ($currentPagePosition + $currentMoviesPerPage); $filePosition ++) {	
		my $filmFolder = $movieContainer[$filePosition];
		my @videoNameSplit;
		my @videoContent;
		my @videoFile;
		
		#$filmFolder contains files or is a file, get a list of those files them from database if available, else from disk:
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
				#We deal only with moviefiles, check that there is a valid file ending:
				if (checkFileEnding($file)) {
					chomp($file);
					my $filename;
					#If $file starts with / then it is a standalone file not in its own folderm the path to it is ready already:
					if(substr($file, 0, 1) eq '/') {$filename = $file;}else{ $filename = $filmFolder. "/" .$file;}
					my $size = -s $filename;
					#Sort samples from full movies:
					if (defined($size) && $size != 0 && $size < $sampleSizeLimit) {
						push(@sampleVideos, $file);
					} elsif(defined($size) && $size != 0 && $size => $sampleSizeLimit) {
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
				$size = 0 if(!defined($size));
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
	print "<tr id=\"addingRowRow\">"; 
		print "<td bgcolor=\"".($lightColor ? "Azure" : "Beige")."\">"."</td>"; #Cell 1 start and end
		print "<td bgcolor=\"".($lightColor ? "Azure" : "Beige")."\"></td>"; #Cell 2
		print "<td bgcolor=\"".($lightColor ? "Azure" : "Beige")."\"><img src=\"/".$urlImagePlacement."addMovieButton.gif\" id=\"addMovieButton\" title=\"Add a movie to this list from the next page\" alt=\"Add a movie to this list from the next page\" onClick=\"addMovieRow('".$lastMovieName."','".$mainScriptName."')\"/></td>";  #Cell 3
	print "</tr>";	
	print "</table>";
	print "<span id=\"lastRowColorSpan\" style=\"display:none;\">".($lightColor ? "Beige" : "Azure")."</span>";
	print "<div id=\"footer_message\" onMouseOut=\"jQuery('footer_message').hide();\" align=\"center\">Stay on Bottom of the Page</div>";
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
	
	print "\n<!-- start full row -->\n";
	print "<tr id=\"".$rowID."-".$X."\">\n"; #starting main row
		print "<td valign=\"top\" OnMouseOver=\"this.style.backgroundColor='Silver';document.getElementById('div-$filePosition-$X').className='whiteBorder';document.getElementById('divB-$filePosition-$X').className='whiteBorder';document.getElementById('divC-$filePosition-$X').className='whiteBorder';\" OnMouseOut=\"this.style.backgroundColor='". $rowColor ."';document.getElementById('div-$filePosition-$X').className='greyBorder';document.getElementById('divB-$filePosition-$X').className='greyBorder';document.getElementById('divC-$filePosition-$X').className='greyBorder';\" bgcolor=\"". $rowColor ."\" width=\"*\">"; #Starting cell 1
		print "<table border=\"0\" align=\"center\" cellspacing=\"0\" width=\"100%\">";
			print "<tr>";
				print "<td colspan=\"2\">" . getRightFolderLink("small") . "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" . $cgi->a({-href=>"/" . $linkContent, -class=>$linkStyle.'-small', -OnMouseOver=>'showSimplePlot(\''.$rowID.'-'.$X.'\',\''.$mainScriptName.'\');', -OnMouseOut=>'jQuery(\'#plotMessageBox\').fadeOut();'}, $displayName . "- Video " . $X) . "<span id=\"name-".$rowID."-".$X."\" style=\"visibility:hidden;\">".$displayName."</span></td>";
				print "<td><div style=\"font-size: 80%;\"><i>Rated:</i><span id=\"ratingContainer\"> " . getDBMovieRating($videoName) . "</span></div></td>"; 
			print "</tr>";
			print "<tr>";
				print "<td width=\"40%\"><div id=\"div-$filePosition-$X\" class=\"greyBorder\">";
					print "<table border=\"0\" height=\"68\"><tr>"; 
					print "<td valign=\"top\"><b class=\"smallBoxHeader-medium\">Details:</b><div style=\"font-size: 80%;\"><b>Genre:</b><span id=\"genreContainer\"> " . getDBMovieGenre($videoName) . "</span><br/><b>Filesize:</b> " . getSize($size) . "<br/><b>Bitrate:</b><span id=\"bitrateContainer\"> " . getBitRateDB($videoName, $filename) . "</span> kb/s</div></td>";
					print "<td valign=\"top\"><div style=\"font-size: 80%;\"><br/><b>Quality:</b><span id=\"qualityContainer\"> " . getResolutionDB($videoName, $filename) . "</span><br/><b>Filetype:</b> " . returnFileType($filename) . "<br/><b>Duration:</b><span id=\"durationContainer\"> " . getDurationDB($videoName, $filename) . " </span></div></td>"; 
					print "</tr></table>";
				print "</div></td>";
				print "<td width=\"24%\"><div id=\"divB-$filePosition-$X\" class=\"greyBorder\">";
					print "<table border=\"0\" height=\"68\"><tr>"; 
						print "<td valign=\"top\"><b class=\"smallBoxHeader-medium\">Recomendations:</b></td>"; 
					print "</tr><tr>";
						print "<td valign=\"top\"><span id=\"suggestionContainer\">".getDBSuggestions($videoName)."</span></td>"; 
					print "</tr>"; 
					print "</table>"; 
				print "</div></td>";
				print "<td width=\"36%\"><div id=\"divC-$filePosition-$X\" class=\"greyBorder\">"; 
					print "<table border=\"0\" height=\"68\"><tr>"; 
						print "<td>";
							print "<table border=\"0\" height=\"60\" style=\"float:left; margin: 0 0 0px 0px;\"><tr><td valign=\"top\" align=\"left\"><b class=\"smallBoxHeader-medium\">Suggestions:</b></td></tr><tr><td valign=\"top\" align=\"left\">".getIMFDBLink($videoName).getIMDBLink($videoName).getNFOOGLELink()."<br/>".getICMDBLink($videoName).getTMDBLink($videoName).getTasteListLink($videoName)."</td></tr>"; 
							print "</table>"; 
						print "</td><td width=\"100%\">"; 
							print "<table style=\"float:right; margin: 0 0 42px 0px;\" border=\"0\"><tr><td style=\"cursor: pointer;\" align=\"right\">".getReloadLink($videoName, $rowID."-".$X)."<span id=\"forceStatus-".$rowID."-".$X."\" style=\"display:none;\">noForcedReload</span></td></tr>"; 
							print "</table>";
						print "</td>";
					print "</tr></table>";
				print "</div></td>";
			print "</tr>";					
		print "</table>";
		print "</td>\n"; #End cell 1
		print "<td width=\"58\" height=\"75\" align=\"center\" bgcolor=\"". $rowColor ."\" id=\"coverCell\"><span id=\"coverContainer\">" . getMovieCover($videoName) . "</span></td>\n"; #Start and End cell 2
		print "<td width=\"114\" height=\"90\" align=\"center\" bgcolor=\"". $rowColor ."\" id=\"trailerCell\"><span id=\"trailerContainer\">" . getTrailer($videoName, $X) . "</span></td>\n"; #Start and End cell 3
	print "</tr>"; #ending main row
	print "\n<!-- end full row -->\n";
}
sub minimalMovieRow {
	my $videoName = shift;
	my $linkContent = shift;
	my $rowColor = shift;
	my $linkStyle = shift;
	my $X = shift;
	my $rowID = getMovieIDByMovieName($videoName);
	my $displayName = nameProcessorWithOffset($videoName);
	
	print "\n<!-- start minimal row -->\n";
	print "<tr id=\"".$rowID."-".$X."\">";
		print "<td valign=\"top\" OnMouseOver=\"this.style.backgroundColor='Silver';\" OnMouseOut=\"this.style.backgroundColor='". $rowColor ."';\" bgcolor=\"". $rowColor ."\" width=\"*\">\n"; #Start cell 1
			print "<table border=\"0\" align=\"center\" cellspacing=\"0\" width=\"100%\">";
			print "<tr><td><!--- ---></td>";
				print "<td>" . getRightFolderLink("small") . "&nbsp;&nbsp;&nbsp;" . $cgi->a({-href=>"/" . $linkContent, -class=>$linkStyle.'-mini'}, $displayName . "- Video " . $X) . "<span id=\"name-".$rowID."-".$X."\" style=\"visibility:hidden;\">".$displayName."</span></td>";
				print "<td><div style=\"font-size: 80%;\"><i>Rated:</i> See above</div></td>"; 
			print "</tr>";
			print "<tr><td width=\"47\"><!--- ---></td>";
				print "<td width=\"*\"><!--- ---></td>";
				print "<td width=\"34%\"><!--- ---></td>";
			print "</tr>";					
			print "</table>";
		print "</td>"; #End cell 1
	print "<td width=\"58\" height=\"40\" align=\"center\" bgcolor=\"". $rowColor ."\"></td>\n"; #Start and End cell 2
	print "<td width=\"114\" height=\"40\" align=\"center\" bgcolor=\"". $rowColor ."\"></td>\n"; #Start and End cell 3
	print "</tr>";
	print "\n<!-- end minimal row -->\n";
}
sub sampleMovieRow {
	my $videoName = shift;
	my $filename = shift;
	my $linkContent = shift;
	my $rowColor = shift;
	my $linkStyle = shift;
	my $rowID = getMovieIDByMovieName($videoName)."-".getFilteredVideoName($filename);
	my $displayName = nameProcessorWithOffset($videoName);
	
	print "\n<!-- start sample row -->\n";
	print "<tr id=\"".$rowID."-sample\">\n";
	print "<td valign=\"top\" OnMouseOver=\"this.style.backgroundColor='Silver';\" OnMouseOut=\"this.style.backgroundColor='". $rowColor ."';\" bgcolor=\"". $rowColor ."\" width=\"*\">\n"; #cell 1 start
		print "<table border=\"0\" align=\"center\" cellspacing=\"0\" width=\"100%\">\n";
		print "<tr><td><!--- ---></td>\n";
			print "<td>" . getRightFolderLink("small");
			print "&nbsp;&nbsp;&nbsp;" . $cgi->a({-href=>"/" . $linkContent, -class=>$linkStyle.'-mini'}, $displayName . "- Sample") . "<span id=\"name-".$rowID."-sample\" style=\"visibility:hidden;\">".$displayName."\n";
			print "</td>\n";
			print "<td><div style=\"font-size: 80%;\"><i>Duration:</i> " . getDurationDB($videoName, $filename) . " </div></td>\n"; 
		print "</tr>";
		print "<tr><td width=\"47\"><!--- ---></td>\n";
			print "<td width=\"*\"><!--- ---></td>\n";
			print "<td width=\"34%\"><!--- ---></td>\n";
		print "</tr>\n";					
		print "</table>\n";
	print "</td>\n"; #End cell 1
	print "<td width=\"58\" height=\"40\" align=\"center\" bgcolor=\"". $rowColor ."\"></td>\n"; #Start and end cell 2
	print "<td width=\"114\" height=\"40\" align=\"center\" bgcolor=\"". $rowColor ."\"></td>\n"; #Start and end cell 3
	print "</tr>\n";
	print "\n<!-- end sample row -->\n";
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