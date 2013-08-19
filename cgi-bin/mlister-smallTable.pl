#!/usr/bin/perl -w
#Creator: Atle Holm - atle@team-holm.net

use CGI;
use strict;
use CGI::Pretty;
use CGI::Carp qw/fatalsToBrowser warningsToBrowser/;
my $cgi=new CGI;

sub createHTMLTable {
	my $movieContainer_r = shift;
	my @movieContainer = @$movieContainer_r;
	my $moviePlacement_r = shift;
	my $moviePlacement = $$moviePlacement_r;
	my $urlMoviePlacement_r = shift;
	my $urlMoviePlacement = $$urlMoviePlacement_r;
	my $currentPagePosition_r = shift;
	my $currentPagePosition = $$currentPagePosition_r;
	my $currentMoviesPerPage_r = shift;
	my $currentMoviesPerPage = $$currentMoviesPerPage_r;

	print "<table border=\"0\" align=\"center\" bgcolor=\"white\" cellspacing=\"0\" width=\"695\" id=\"theMovieListerTable\">";
	print "<!-- small table -->\n";
	print "<tr><th>Title</th><th>Cover</th><th>Trailer</th></tr>";
	my $lightColor = 0;

	for (my $filePosition = $currentPagePosition; $filePosition <= ($currentPagePosition + $currentMoviesPerPage); $filePosition ++) {	
		my $folderContent = $movieContainer[$filePosition];
		my @videoNameSplit;
		my @videoContent;
		my @videoFile;
		if ($folderContent) {
			@videoNameSplit =  split('/', $folderContent);
			@videoContent = `ls "$folderContent"`;
		} else {
			next;
		}
		my $videoName = $videoNameSplit[(scalar @videoNameSplit) - 1];
		my $lastField = $videoNameSplit[(scalar @videoNameSplit) - 1];

		foreach my $file (@videoContent) {
			if (checkFileEnding($file)) {
				push(@videoFile, $file);	
			}
		}
		my $X = 0;
		foreach my $vid (@videoFile) { 
			$X ++;
			my $filename;
			my $linkContent;
			if(checkFileEnding($lastField)) {
				$filename = $moviePlacement . $lastField;
				$linkContent = $urlMoviePlacement . $lastField;
				$videoName = nameProcessor($videoName);
			} else {
				$filename = $moviePlacement . $lastField . "/$vid";
				$linkContent = $urlMoviePlacement . $lastField . "/$vid";
			}
			my $rowID = getMovieIDByMovieName($videoName);
			chomp($filename);
			my $size = -s $filename;
			if ($lightColor eq 0) {
				if ($size < 100994432) {
					print "<tr id=\"".getMovieIDByMovieName($videoName)."-".getFilteredVideoName($filename)."-sample\"><td OnMouseOver=\"style.backgroundColor='Silver';\" OnMouseOut=\"style.backgroundColor='Beige';\" bgcolor=\"Beige\" width=\"*\">";
					print $cgi->a({-href=>"/" . $linkContent, -class=>'movieLinks-red-small'}, "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" . nameProcessorWithOffset($videoName) . "- Video Sample");
					print $cgi->br."&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style=\"font-size: 80%;\"><i>Rated:</i> " . getDBMovieRating($videoName) . "</span></td><td width=\"39\" height=\"50\" align=\"center\" bgcolor=\"Beige\">" . getMovieCover($videoName) . "</td>";
					print "<td width=\"76\" height=\"60\" align=\"center\" bgcolor=\"Beige\">" . getTrailer($videoName, $X) . "</td>";			
					print "</tr>";
					$X --;
				} else {
					print "<tr id=\"".getMovieIDByMovieName($videoName)."-".$X."\"><td OnMouseOver=\"style.backgroundColor='Silver';\" OnMouseOut=\"style.backgroundColor='Beige';\" bgcolor=\"Beige\" width=\"*\">";
					print $cgi->a({-href=>"/" . $linkContent, -class=>'movieLinks-red-small', -OnMouseOver=>'showSimplePlot(\''.$rowID.'-'.$X.'\');', -OnMouseOut=>'jQuery(\'#plotMessageBox\').fadeOut();'}, "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" . nameProcessorWithOffset($videoName) . "- Video " . $X);
					print $cgi->br."&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style=\"font-size: 80%;\"><i>Rated:</i><span id=\"ratingContainer\"> " . getDBMovieRating($videoName) . "</span><span id=\"name-".getMovieIDByMovieName($videoName)."-".$X."\" style=\"visibility:hidden;\">".nameProcessorWithOffset($videoName)."</span></span></td><td width=\"39\" height=\"50\" align=\"center\" bgcolor=\"Beige\">" . getMovieCover($videoName) . "</td>";
					print "<td width=\"76\" height=\"60\" align=\"center\" bgcolor=\"Beige\">" . getTrailer($videoName, $X) . "</td>";
					print "</tr>";
				}
				$lightColor = 1;
			} else {
				if ($size < 100994432) {
					print "<tr id=\"".getMovieIDByMovieName($videoName)."-".getFilteredVideoName($filename)."-sample\"><td OnMouseOver=\"style.backgroundColor='Silver';\" OnMouseOut=\"style.backgroundColor='Azure';\" bgcolor=\"Azure\" width=\"*\">";
					print $cgi->a({-href=>"/" . $linkContent, -class=>'movieLinks-black-small'}, "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" . nameProcessorWithOffset($videoName) . "- Video Sample");
					print $cgi->br."&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style=\"font-size: 80%;\"><i>Rated:</i> " . getDBMovieRating($videoName) . "</span></td><td width=\"39\" height=\"50\" align=\"center\" bgcolor=\"Azure\">" . getMovieCover($videoName) . "</td>";
					print "<td width=\"76\" height=\"60\" align=\"center\" bgcolor=\"Azure\">" . getTrailer($videoName, $X) . "</td>";
					print "</tr>";
					$X --;
				} else {
					print "<tr id=\"".getMovieIDByMovieName($videoName)."-".$X."\"><td OnMouseOver=\"style.backgroundColor='Silver';\" OnMouseOut=\"style.backgroundColor='Azure';\" bgcolor=\"Azure\" width=\"*\">";
					print $cgi->a({-href=>"/" . $linkContent, -class=>'movieLinks-black-small', -OnMouseOver=>'showSimplePlot(\''.$rowID.'-'.$X.'\');', -OnMouseOut=>'jQuery(\'#plotMessageBox\').fadeOut();'}, "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" . nameProcessorWithOffset($videoName). "- Video " . $X);
					print $cgi->br."&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style=\"font-size: 80%;\"><i>Rated:</i><span id=\"ratingContainer\"> " . getDBMovieRating($videoName) . "</span><span id=\"name-".getMovieIDByMovieName($videoName)."-".$X."\" style=\"visibility:hidden;\">".nameProcessorWithOffset($videoName)."</span></span></td><td width=\"39\" height=\"50\" align=\"center\" bgcolor=\"Azure\">" . getMovieCover($videoName) . "</td>";
					print "<td width=\"76\" height=\"60\" align=\"center\" bgcolor=\"Azure\">" . getTrailer($videoName, $X) . "</td>";
					print "</tr>";
				}
				$lightColor = 0;
			}
		}
	}
	print "</table>";
	print "<div id=\"footer_message\" onMouseOut=\"document.getElementById('footer_message').style.visibility='hidden';\" align=\"center\">Stay on Bottom of the Page</div>";
}
1;