//If we are offline, load a local definition of jQuery instead:
window.onload = function() {
	window.jQuery || function() {
		var script = document.createElement('script');
		script.src = '/movieLister/js/jquery-1.9.1.min.js';
		document.body.appendChild(script);
	};
};
jQuery(document).ready(function() {
	jQuery('#footer_barsign').click(function() {
		var imagePlacement = jQuery(this).attr('src').split('/')[1];
		jQuery('#footer_controlbar').fadeToggle('slow', function() { 
			if(jQuery('#footer_barsign').attr('src') == "/"+imagePlacement+"/minusSign_small.png") {
				jQuery('#footer_barsign').attr('src', "/"+imagePlacement+"/plusSign_small.png");
				if(!jQuery('#bottom_controlbar_controller').is(":visible")) jQuery('#bottom_controlbar_controller').fadeIn('slow');
			} else {
				jQuery('#footer_barsign').attr('src', "/"+imagePlacement+"/minusSign_small.png");
				if(jQuery('#bottom_controlbar_controller').is(":visible")) jQuery('#bottom_controlbar_controller').fadeOut('slow');
			}
		});
	});
	jQuery('#bottom_barsign').click(function() {
		var imagePlacement = jQuery(this).attr('src').split('/')[1];
		jQuery('#bottom_controlbar').fadeToggle('slow', function() { 
			if(jQuery('#bottom_barsign').attr('src') == "/"+imagePlacement+"/minusSign_small_white.png") {
				jQuery('#bottom_barsign').attr('src', "/"+imagePlacement+"/plusSign_small.png");
				if(!jQuery('#bottom_breaklines').is(":visible")) jQuery('#bottom_breaklines').fadeIn('slow');
			} else {
				jQuery('#bottom_barsign').attr('src', "/"+imagePlacement+"/minusSign_small_white.png");
				if(jQuery('#bottom_breaklines').is(":visible")) jQuery('#bottom_breaklines').fadeOut('slow');
			}
		});
	});
	jQuery('#addingRowRow').css('height',(parseInt(jQuery('#coverCell:last').css('height'))) + 'px');
	if(jQuery('.coverInsteadOfTrailer').length > 0) jQuery('#addMovieButton').css('height',(parseInt(jQuery("img[name='imgImageCover']:last").css('height'))) + 'px').css('width',(parseInt(jQuery('.coverInsteadOfTrailer:last').css('width'))) + 'px');
	else jQuery('#addMovieButton').css('height',(parseInt(jQuery("img[name='imgImageCover']:last").css('height'))) + 'px').css('width',(parseInt(jQuery('#movieTrailerFrame:last').css('width'))) + 'px');
});
jQuery(window).load(function() {
	placeTrailerText();
	display_footer_message();
	jQuery("#bottom_controlbar").appendTo('#addingRowRow td:first');
	//Set the height of all the info boxes in every move row to the same:
	var greyBorderHeight = jQuery('.greyBorder:last').css('height');
	jQuery('.greyBorder').each(function() {
		jQuery(this).css('height', greyBorderHeight);
	});
});
jQuery(window).bind("load", function() {
    jQuery('#pre_loading').fadeOut(2000);
});
jQuery(window).resize(function(){
	placeTrailerText();
    movediv();
});
Event.observe(window, 'scroll', function() {
    movediv();
});
var n = 0; //used for flashing the reloadButton
function movediv() {
	jQuery('#footer_message').css('top', jQuery(window).scrollTop() + jQuery(window).height() - parseInt(jQuery('#footer_message').css('height')) + 'px');
	jQuery('#footer_controlbar').css('top', (jQuery(window).scrollTop() + jQuery(window).height() - 16) - parseInt(jQuery('#footer_controlbar').css('height')) + 'px').css('left','0px').css('width',jQuery(document).innerWidth()-8);
	jQuery('#footer_controlbar_controller').css('top', (jQuery(window).scrollTop() + jQuery(window).height() - 13) - parseInt(jQuery('#footer_controlbar_controller').css('height')) + 'px').css('left','4px');
	jQuery('#bottom_controlbar_controller').css('top', (jQuery(window).scrollTop() + jQuery(window).height() - 33) - parseInt(jQuery('#bottom_controlbar_controller').css('height')) + 'px').css('left','4px');
	jQuery('#header_showbar').css('top', jQuery(window).scrollTop() + 'px').css('left','0px').css('width',jQuery(document).innerWidth()-8);
}
function display_footer_message() {
	jQuery('#footer_message').css('height','20px');
	movediv();  //sync reload
}
function placeTrailerText() {
	var pageSize = document.getElementById('pageSize').value;
	var trailerTextCounter = 0;
	jQuery("img[class='coverInsteadOfTrailer']").each(function() {
		var position = jQuery(this).position();
		jQuery('.trailerText:eq('+trailerTextCounter+')').css('top', position.top + 16 + (pageSize == "big" ? 12 : 0) + 'px').css('left', position.left + (parseInt(jQuery(this).css('width'))/2) - 26 - (pageSize == "big" ? 24 : 1) +'px').css('visibility','visible');
		if (pageSize == "big") jQuery('.trailerText:eq('+trailerTextCounter+')').addClass('trailerTextBig');
		trailerTextCounter++;
	});
}
function changePositionFont(color) {
	jQuery('#positionFont').css('color',color);
}
function showZoomPlayButton(pictureURL, spanID) {
	var position = jQuery("img[src$='"+pictureURL+"'][class='coverInsteadOfTrailer'][id='"+spanID+"']").position();
	jQuery('.zoom-playButton#'+spanID).css('top', position.top).css('left', position.left).css('visibility','visible');
	jQuery("img[src$='"+pictureURL+"'][class='coverInsteadOfTrailer'][id='"+spanID+"']").css('opacity',.7).css('filter','url("data:image/svg+xml;utf8,<svg xmlns=\'http://www.w3.org/2000/svg\'><filter id=\'grayscale\'><feColorMatrix type=\'matrix\' values=\'1 0 0 0 0, 0 1 0 0 0, 0 0 1 0 0, 0 0 0 1 0\'/></filter></svg>#grayscale")');
	jQuery("img[src$='"+pictureURL+"'][class='coverInsteadOfTrailer'][id='"+spanID+"']").css('-webkit-filter','grayscale(0%)').css('border', '1px dashed').css('border-color', 'red');
	jQuery('.trailerText#'+spanID).css('visibility','hidden');
}
function hideZoomPlayButton(pictureURL, spanID) {
	var position = jQuery("img[src$='"+pictureURL+"'][class='coverInsteadOfTrailer'][id='"+spanID+"']").position();
	jQuery('.zoom-playButton#'+spanID).css('top', position.top).css('left', position.left).css('visibility','hidden');
	jQuery("img[src$='"+pictureURL+"'][class='coverInsteadOfTrailer'][id='"+spanID+"']").css('opacity',.4).css('filter','url("data:image/svg+xml;utf8,<svg xmlns=\'http://www.w3.org/2000/svg\'><filter id=\'grayscale\'><feColorMatrix type=\'matrix\' values=\'0.3333 0.3333 0.3333 0 0 0.3333 0.3333 0.3333 0 0 0.3333 0.3333 0.3333 0 0 0 0 0 1 0\'/></filter></svg>#grayscale")');
	jQuery("img[src$='"+pictureURL+"'][class='coverInsteadOfTrailer'][id='"+spanID+"']").css('-webkit-filter','grayscale(100%)').css('border', '0px').css('border-color', 'red').css('filter','gray');
	jQuery('.trailerText#'+spanID).css('visibility','visible');
}
function stampRotate(buttonID) {
	var strSource = jQuery('#'+buttonID).attr('src');
	var imageFile = strSource.split('/')[strSource.split('/').length-1];
	if (imageFile == 'stampbig.png') jQuery('#'+buttonID).attr('src', '/' + urlImagePlacement + 'stampsmall.png');
	if (imageFile == 'stampmedium.png') jQuery('#'+buttonID).attr('src', '/' + urlImagePlacement + 'stampbig.png');
	if (imageFile == 'stampsmall.png') jQuery('#'+buttonID).attr('src', '/' + urlImagePlacement + 'stampmedium.png');
}
function toggleMovieRefresh(myID, movieName, imagePlacement) {
	if(jQuery('#reloadMovieButton-' + myID).attr('src') == "/"+imagePlacement+"reloadMovie.png") {
		jQuery('#reloadMovieButton-' + myID).attr('src', "/"+imagePlacement+"reloadMovieCheck.gif");
		jQuery('#forceStatus-' + myID).text('forcedReload');
	} else if(jQuery('#reloadMovieButton-' + myID).attr('src') == "/"+imagePlacement+"reloadMovieCheck.gif") {
		jQuery('#reloadMovieButton-' + myID).attr('src', "/"+imagePlacement+"reloadMovie.png");
		jQuery('#forceStatus-' + myID).text('noForcedReload');
	}
}
function navigationSubmit(buttonType, tableStampSize) {
	var pageNumberHolder = document.getElementById('pageNumberHolder').value;
	var numberOfPages = document.getElementById('numberOfPages').innerHTML;
	var OKContinue = false;
	if(!isNaN(pageNumberHolder) && !isNaN(numberOfPages)) { 
		pageNumberHolder = parseInt(pageNumberHolder);
		numberOfPages = parseInt(numberOfPages);
		if(buttonType == 'next') {
			if(pageNumberHolder != numberOfPages) {
				if(buttonType == 'next' && !isNaN(pageNumberHolder)) { document.getElementById('pageNumberHolder').value = pageNumberHolder + 1; OKContinue = true;}
			} else {
				alert('You can not navigate beyond the last page..');
			}
		}
		if(buttonType == 'prev') {
			if(pageNumberHolder != 1) {
				if(buttonType == 'prev' && !isNaN(pageNumberHolder)) { document.getElementById('pageNumberHolder').value = pageNumberHolder - 1; OKContinue = true;}
			} else {
				alert('You can not navigate before the first page..');
			}
		}
		if(OKContinue) {
			var tableStampSizeImg = document.getElementById(tableStampSize).src;
			var stampSizeName = tableStampSizeImg.split('/')[tableStampSizeImg.split('/').length-1];
			stampSizeName = stampSizeName.substr(0,stampSizeName.indexOf('.'));
			stampSizeName = stampSizeName.slice(5);
			if(document.getElementById('pageSize').value != stampSizeName && !isNaN(pageNumberHolder)) {
				if(confirm('You have chosen to change the table size, are you sure?')) {
					document.getElementById('pageSize').value = stampSizeName;
				}
			}
			document.getElementById('navigationForm').submit();
		}
	}
}
function flashAndSubmitReloadButton(buttonName, serverSideScriptName) {
	if(++n<=6) setTimeout(new Function("document.getElementById('"+buttonName+"').src='/" + urlImagePlacement + (n%2?'reload-3.png':'reload-3red.png') + "';flashAndSubmitReloadButtonAgain('"+buttonName+"')"), 350);
	var strIDCollection = getAllMovieRowIDs();
	var originalHTML = {};
	var httpRequests = {};
	var pageSize = document.getElementById('pageSize').value;

	for (var movieRowIndex in strIDCollection) {
		if(!isNaN(movieRowIndex)) {
			var myID = strIDCollection[movieRowIndex];
			originalHTML[myID] = jQuery('#'+myID).html();
		}
	}
	var index;
	for (index = 0; index < strIDCollection.length; ++index) {
		//Get the new Row info and update it:
		//Example taken from - https://developer.mozilla.org/en-US/docs/AJAX/Getting_Started
		var myID = strIDCollection[index];
		if(myID.slice(-7) != "-sample") {
			var tempSplit = myID.split("-");
			var videoNumber = tempSplit[tempSplit.length-1];
			if (!isNaN(videoNumber)) { 
				videoNumber = parseInt(videoNumber);
				var movieID = myID.substring(0, myID.indexOf("-"));
				//We figure out how many movie files are associated with an ID:
				var noFiles = 0;
				for (var movieRowIndex in strIDCollection) {
					if(!isNaN(movieRowIndex) && !isNaN(movieID)) {
						if(movieID == strIDCollection[movieRowIndex].substring(0, strIDCollection[movieRowIndex].indexOf("-"))) noFiles++;
					}
				}
				if(((videoNumber == 1 || videoNumber == 2) && noFiles > 1) || noFiles == 1) {
					if (!isNaN(movieID)) {
						var url = encodeURI(window.location.protocol + "//" + window.location.host + "/movieLister/cgi-bin/" + serverSideScriptName + "?qid=" + movieID);
						movieID = parseInt(movieID);
						if (window.XMLHttpRequest) { // Mozilla, Safari, ...
							httpRequests[myID] = new XMLHttpRequest();
						} else if (window.ActiveXObject) { // IE
							try {
								httpRequests[myID] = new ActiveXObject("Msxml2.XMLHTTP");
							} catch (e) {
								alert(e);
								try {
									httpRequests[myID] = new ActiveXObject("Microsoft.XMLHTTP");
								} catch (e) {alert(e);}
							}
						}
						if (!httpRequests[myID]) {
							alert('Giving up - cannot create an XMLHTTP instance');
							return false;
						}
						//Oppdatere web side:
						var forcedReload = false;
						var currentMovieNameFetchedWithID = document.getElementById('name-'+myID).innerHTML;
						if(currentMovieNameFetchedWithID) {
							if(myID.split("-")[1] == 1 && document.getElementById('forceStatus-' + myID) && document.getElementById('forceStatus-' + myID).innerHTML == "forcedReload") forcedReload = true;
							httpRequests[myID].onreadystatechange = new handleRowUpdateRequest(myID, httpRequests[myID], originalHTML[myID], currentMovieNameFetchedWithID, pageSize);
							httpRequests[myID].open('GET', forcedReload ? url + "&forceReload="+movieID : url, true);
							httpRequests[myID].send();
						}
					}				
				}
			}
		}
	}
	//Scroll to top and set refreshbutton back to original look:
	jQuery('body,html').animate({scrollTop:0}, 'slow');
	//setTimeout(window.scrollTo(0, 0), 250); 
	//setTimeout(document.body.scrollTop = document.documentElement.scrollTop = 0, 250); 
	//setTimeout(document.getElementById('"+buttonName+"').src='/' + urlImagePlacement + 'reload-1.png', 3500);
	function handleRowUpdateRequest(myID, httpRequest, originalHTML, htmlName, pageSize) {
		//Mangler å legge inn originalHTML med oppdaterte verdier hvis disse er oppdatert
		//Skal vise oppdaterte verdier i rødt som fades ut etter 30 sekunder - mangler
		var rowFactor, linkRevisor;
		var coverCachePlacement = "movieLister/coverCache";
		if(pageSize == "big") {
			rowFactor = 1;
			linkRevisor = "";
		} else if(pageSize == "medium") {
			rowFactor = 0.6;
			linkRevisor = "-medium";
		} else if(pageSize == "small") {
			rowFactor = 0.4;
			linkRevisor = "-small";
		} else {
			rowFactor = 0.6;
			linkRevisor = "-medium";
		}
		return function() {
			if (httpRequest.readyState === 4) {
				if (httpRequest.status === 200) {
					//Get the information and return it
					var xml_response = httpRequest.responseXML;
					var id = xml_response.getElementsByTagName("id")[0].firstChild.nodeValue;
					var movieName  = xml_response.getElementsByTagName("name")[0].firstChild.nodeValue;
					var movieRating = xml_response.getElementsByTagName("rating")[0].firstChild.nodeValue;
					var movieGenre = xml_response.getElementsByTagName("genre")[0].firstChild.nodeValue;
					var suggestions = xml_response.getElementsByTagName("suggestions")[0].firstChild.nodeValue;
					var movieCover = xml_response.getElementsByTagName("cover")[0].firstChild.nodeValue;
					var movieTrailer = xml_response.getElementsByTagName("trailer")[0].firstChild.nodeValue;
					var embedable = xml_response.getElementsByTagName("embedable")[0].firstChild.nodeValue;
					//Fade the row out and in again with the new content:
					var htmlRow;
					if(myID) htmlRow = document.getElementById(myID).innerHTML;
					if(myID && htmlRow) {
						//First we get the code we are going to replace:
						jQuery('#'+myID).animate({ opacity: 'hide', height: 'hide'}, 'fast');
						var ratingSpan, genreSpan, suggestionSpan, coverSpan, trailerSpan;
						if(originalHTML.indexOf('<span id="ratingContainer">') >= 0) ratingSpan = (originalHTML.substring(originalHTML.indexOf('<span id="ratingContainer">'),originalHTML.length)).substring(0,(originalHTML.substring(originalHTML.indexOf('<span id="ratingContainer">'),originalHTML.length)).indexOf('</span>')+7);
						if(originalHTML.indexOf('<span id="genreContainer">') >= 0) genreSpan = (originalHTML.substring(originalHTML.indexOf('<span id="genreContainer">'),originalHTML.length)).substring(0,(originalHTML.substring(originalHTML.indexOf('<span id="genreContainer">'),originalHTML.length)).indexOf('</span>')+7);
						if(originalHTML.indexOf('<span id="suggestionContainer">') >= 0) suggestionSpan = (originalHTML.substring(originalHTML.indexOf('<span id="suggestionContainer">'),originalHTML.length)).substring(0,(originalHTML.substring(originalHTML.indexOf('<span id="suggestionContainer">'),originalHTML.length)).indexOf('</span>')+7);
						if(originalHTML.indexOf('<span id="coverContainer">') >= 0) coverSpan = (originalHTML.substring(originalHTML.indexOf('<span id="coverContainer">'),originalHTML.length)).substring(0,(originalHTML.substring(originalHTML.indexOf('<span id="coverContainer">'),originalHTML.length)).indexOf('</span>')+7);
						if(originalHTML.indexOf('<span id="trailerContainer">') >= 0) trailerSpan = (originalHTML.substring(originalHTML.indexOf('<span id="trailerContainer">'),originalHTML.length)).substring(0,(originalHTML.substring(originalHTML.indexOf('<span id=trailerContainer">'),originalHTML.length)).indexOf('</span>')+7);
						if(coverSpan && coverSpan.split('/').length > 1) coverCachePlacement = coverSpan.split('/')[1] + "/" + coverSpan.split('/')[2];
						//Next we generate the code we want to replace with:
						var newRatingSpan = '<span id="ratingContainer">'+movieRating+'</span>';
						var newGenreSpan = '<span id="genreContainer">'+movieGenre+'</span>';
						var newSuggestionSpan = '<span id="suggestionContainer">';
						
						if(suggestions.match(/no suggestions/gi)) {
							newSuggestionSpan += '<a target="_blank" class="suggestionLinks'+linkRevisor+'" href="http://www.tastekid.com">No Suggestions Found..</a><br/>';
						} else {
							var suggestionArray = suggestions.split(' - ');
							for (var sIndex in suggestionArray) {
								var mySuggestion = suggestionArray[sIndex];
								if(mySuggestion && mySuggestion != ' ') newSuggestionSpan += '<a target="_blank" class="suggestionLinks'+linkRevisor+'" href="http://www.themoviedb.org/search?search='+encodeURIComponent(mySuggestion)+'">'+mySuggestion+'</a><br/>';
							}
						}
						newSuggestionSpan += '</span>';
						var newCoverSpan;
						if(movieCover.split('/')[movieCover.split('/').length-1] == "NONE-ADDED") {
							newCoverSpan = '<span id="coverContainer"><img src="/'+coverCachePlacement+'/warning.png" width="'+(rowFactor*97)+'" height="'+(rowFactor*125)+'" border="0" alt="Cover Not Found" /></a></span>';
						} else {
							newCoverSpan = '<span id="coverContainer"><a href="/'+coverCachePlacement+'/'+movieCover.split('/')[movieCover.split('/').length-1]+'" rel="lightbox" title="'+movieName+'"><img src="/'+coverCachePlacement+'/'+movieCover.split('/')[movieCover.split('/').length-1]+'" width="'+(rowFactor*89)+'" height="'+(rowFactor*157)+'" border="0" alt="'+movieName+'" /></a></span>';
						}
						var newTrailerSpan; 
						if(movieTrailer == 'http://www.imdb.com' && trailerSpan) { 
							newTrailerSpan = '<a href="http://www.imdb.com" target="newWindow"><img src="/movieLister/'+trailerSpan.split('/')[4]+'/playButton.png" width="' + (rowFactor*190) + '" height="' + (rowFactor*150) + '" border="0" /></a>'; 
						} else {
							newTrailerSpan = '<span id="trailerContainer"><iframe width="'+(rowFactor*190)+'" height="'+(rowFactor*150)+'" src="'+ movieTrailer +'" frameborder="0" allowfullscreen=""></iframe></span></td>';
						}
						//Now we do the transform and place the new HTML in the webpage:
						if(ratingSpan) {
							var regex = new RegExp(ratingSpan, 'g');
							originalHTML = originalHTML.replace(regex, newRatingSpan);
						}
						if(genreSpan) {
							var regex = new RegExp(genreSpan, 'g');
							originalHTML = originalHTML.replace(regex, newGenreSpan);
						}
						if(suggestionSpan) {
							var regex = new RegExp(suggestionSpan, 'g');
							originalHTML = originalHTML.replace(regex, newSuggestionSpan);
						}
						if(coverSpan) {
							var regex = new RegExp(coverSpan, 'g');
							originalHTML = originalHTML.replace(regex, newCoverSpan);
						}
						if(trailerSpan) {
							var regex = new RegExp(trailerSpan, 'g');
							originalHTML = originalHTML.replace(regex, newTrailerSpan);
						}
						jQuery('#'+myID).html(originalHTML);
						jQuery('#'+myID).animate({ opacity: 'show', height: 'show'}, 'slow');
					}
					placeTrailerText();
				} else {
					var htmlRow;
					if(myID) htmlRow = document.getElementById(myID).innerHTML;
					if(myID && htmlRow) {
						if(htmlRow.match(/Beige/gi)) jQuery('#'+myID).html('<td valign="top" colspan="3" OnMouseOver="this.style.backgroundColor=\'Silver\';" OnMouseOut="this.style.backgroundColor=\'Beige\';" bgcolor="Beige" width="*"><center><b class=\"smallBoxHeader-'+pageSize+'\"><font color="red">Something wrong happened.<br/>Please reload!</font></b><br/></center></td>');
						if(htmlRow.match(/Azure/gi)) jQuery('#'+myID).html('<td valign="top" colspan="3" OnMouseOver="this.style.backgroundColor=\'Silver\';" OnMouseOut="this.style.backgroundColor=\'Azure\';" bgcolor="Azure" width="*"><center><b class=\"smallBoxHeader-'+pageSize+'\"><font color="red">Something wrong happened.<br/>Please reload!</font></b><br/></center></td>');
					}
				}
			} else {
				//We are loading, show loading animation..
				var htmlRow;
				if(myID) htmlRow = jQuery('#'+myID).html();
				if(myID && htmlRow) {
					if(htmlRow.match(/Beige/gi)) jQuery('#'+myID).html('<td valign="top" colspan="3" OnMouseOver="this.style.backgroundColor=\'Silver\';" OnMouseOut="this.style.backgroundColor=\'Beige\';" bgcolor="Beige" width="*"><center><b class=\"smallBoxHeader-'+pageSize+'\"><font size="4">Searching for updated content for..</font><br/><font color="red" size="3">'+htmlName+'</b></font><br/><img src="/'+ urlImagePlacement +'loading-2.gif" /></center></td>');
					if(htmlRow.match(/Azure/gi)) jQuery('#'+myID).html('<td valign="top" colspan="3" OnMouseOver="this.style.backgroundColor=\'Silver\';" OnMouseOut="this.style.backgroundColor=\'Azure\';" bgcolor="Azure" width="*"><center><b class=\"smallBoxHeader-'+pageSize+'\"><font size="4">Searching for updated content for..</font><br/><font color="red" size="3">'+htmlName+'</b></font><br/><img src="/'+ urlImagePlacement +'loading-2.gif" /></center></td>');
				}
			}
		}
	}
}
function showSimplePlot(idn, serverSideScriptName) {
	var movieID = idn.split('-')[0];
	//var videoID = idn.split('-')[1];
    var url = encodeURI(window.location.protocol + "//" + window.location.host + "/movieLister/cgi-bin/" +serverSideScriptName); 
	jQuery.ajax({
		type: 'GET',
		url: url,
		data: 'simplePlotID='+movieID,
		dataType: "xml",
		async: false,
		success: function(xml) {
			jQuery(xml).find('plotinfo').each(function(){
				var moviename = jQuery(this).find('moviename').text();
				var year = jQuery(this).find('year').text();
				var plot = jQuery(this).find('plot').text();
				if(plot != "0") showPlotBox('<b>' + moviename +'</b> - ' + (year==0 ? '<font size="2">Unknown production year</font>' : year) + ' <br/>'+ plot);
				else showPlotBox('<b>' + moviename +'</b>: <br/>&nbsp;&nbsp;&nbsp;No plot was found.');
			});
		}
	});
	function showPlotBox(plotText) {
		var position = jQuery('#name-'+idn).position();
		jQuery('#plotMessageBox').html(plotText).css('position','absolute').css('top', position.top + 25).css('left', position.left - 120).css('width','400').fadeIn('slow');
	}
}
function addMovieRow(mName, serverSideScriptName) {
	/* 
		1. Hent neste rad/rader etter mName fra serverside scriptet.
		2. Insert den etter siste rad i tabellen.
	*/
	var url = encodeURI(window.location.protocol + "//" + window.location.host + "/movieLister/cgi-bin/" +serverSideScriptName);
	var secondLastRow = jQuery('#theMovieListerTable tr').eq(-2);
	var color = jQuery('#lastRowColorSpan').text();
	var row, nextName, totalRows, error;
	jQuery.ajax({
		type: 'GET',
		url: url,
		data: 'getMovieAfter='+mName+'&lastRowColor='+color,
		dataType: "xml",
		async: false,
		success: function(xml) {
			jQuery(xml).find('nextMovieInfo').each(function(){
				nextName = jQuery(this).find('name').text();
				totalRows = jQuery(this).find('totalRows').text();
				row = jQuery(this).find('row').text();
				error = jQuery(this).find('error').text();				
			});
		}
	});
	if(!error) {
		row = row.substr(9); /*Remove Cdata*/
		row = row.substring(0, row.length - 2); /*Remove end of Cdata*/
		secondLastRow.before(row);
		placeTrailerText();
		jQuery('#addMovieButton').attr('onClick',"addMovieRow('"+nextName+"','"+serverSideScriptName+"')");
		if(totalRows % 2) jQuery('#lastRowColorSpan').text(color == 'Azure' ? ' Beige' : 'Azure');
		else jQuery('#lastRowColorSpan').text(color == 'Azure' ? ' Azure' : 'Beige');
	} else {
		jQuery('#addMovieButton').attr('onClick',"addMovieRow('"+nextName+"','"+serverSideScriptName+"')");
		alert('You reached the end of your movie files list cache. Next add to this page will start from the beginning of the list.');
	}
}
function flashAndSubmitReloadButtonAgain(buttonName) {
	if(++n<=6) setTimeout(new Function("document.getElementById('"+buttonName+"').src='/" + urlImagePlacement + (n%2?'reload-3.png':'reload-3red.png') + "';flashAndSubmitReloadButtonAgain('"+buttonName+"')"), 350); 
}
function onMouseOverReloadButton(buttonName) {
	n = 0;
	document.getElementById(buttonName).src='/' + urlImagePlacement + 'reload-2.png';
}
function pause(ms) {
	var date = new Date();
	var curDate = null;
	do { curDate = new Date(); } 
	while(curDate-date < ms);
}
function getAllMovieRowIDs() {
	var strIDCollection = [];
	jQuery.each(jQuery('#theMovieListerTable tr'), function() {
		if ($(this).id.length > 0) {
			strIDCollection.push($(this).id);
		}
	});
	return strIDCollection;
}