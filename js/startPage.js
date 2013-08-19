//If we are offline, load a local definition of jQuery instead:
var urlMain = encodeURI(window.location.protocol + "//" + window.location.host + "/movieLister/cgi-bin/movieLister.pl");
var confScriptPlacement = '/etc/movieLister/';
var mainConfigSet = '/usr/share/movieLister/setup/master-config.conf';
var error;
var openLister={
	show:function() { $('#loading').show();},	
}
window.onload = function() {
	window.$ || function() {
		var script = document.createElement('script');
		script.src = '/movieLister/js/$-1.9.1.min.js';
		document.body.appendChild(script);
	};
};
jQuery(window).resize(function(){
    movediv();
});
$(window).scroll(movediv);
$(window).load(function() {
	$('#local_bottom_showbar').css('height',$('.local_header_showbar').css('height')).css('width', $('.local_header_showbar').css('width'));
});
$(document).ready(function() {
	$('.dropdown-menu li:eq(0)').click(function() {
		$('#modalAddRepository').modal('show');
	});
	$('.dropdown-menu li:eq(1)').click(function() {
		var mdlRemoveBody = $('#repositoryRemoveList');
		var mySelectedRepo = $('.selectedRow4Repo');
		if(mySelectedRepo.length == 0) {	
			mdlRemoveBody.html('<ul><li>No repository selected.</li></ul>');					
		} else {			
			var liList = "";
			mySelectedRepo.each(function(i, obj) {
				liList += '<li>'+trimString(obj.textContent+'</li>');
			});
			mdlRemoveBody.html('<ul>'+liList+'</ul>');		
		}
		$('#modalRemoveRepository').modal('show');
	});
	$('.dropdown-menu li:eq(2)').click(function() {
		$('#modalShowError').modal('show');
		if(!$('#errorMessage').html()) {
			$('#mdlErroMessageLabel').text('No error found');
			$('#errorMessage').text('There were no errors found that could be displayed here. This most likely means that everything is running smoothly.');
			$('#modalShowError').on('hidden', function () {
				$('#errorMessage').text('');
			});
		}
	});
	$('#modalRemoveRepositoryBtn').click(function() {
		var confname = $('.selectedRow4Repo').text();
		$('#modalRemoveRepository').modal('hide');
		error = undefined;
		if(typeof confname !== 'undefined' && confname != "") {
			removeRepository(confname);
		}
		return false;
	});
	setSpan4RepoClickAction();
	if(getMainConfig()) {
		updateRepoList();	
	}
	//Setter ny database bruker i main config:
	$('#formdbMainUserUpdate').submit(function() {
		//param('JSONconfigset') -> hash med verdier
		//param('setRepository') -> sti til repository
		var dbUser = $('input[id=dbUserCellInput]').val();
		var confset = mainConfigSet;
		var hashvalues = {dbUser:dbUser};
		var postData = 'JSONconfigset=' + encodeURIComponent(JSON.stringify(hashvalues))+'&setRepository='+encodeURIComponent(confset);
		$.ajax({
			type: 'GET',
			url: urlMain,
			contentType: 'application/json',
			datatype: 'json',
			data: postData,
			async: true,
			success: function() {
				//getMainConfig();
				$('#dbUserCellInput').fadeOut('fast', function () {
					$('#dbUserCellInput').fadeIn('slow');
				});
			}
		});
		return false;
	});
	//Setter database brukers passord i main config:
	$('#formdbMainUserPasswordUpdate').submit(function() {
		//param('JSONconfigset') -> hash med verdier
		//param('setRepository') -> sti til repository
		var dbPassword = $('input[id=dbPasswordCellInput]').val();
		var confset = mainConfigSet;
		var hashvalues = {dbPassword:dbPassword};
		var postData = 'JSONconfigset=' + encodeURIComponent(JSON.stringify(hashvalues))+'&setRepository='+encodeURIComponent(confset);
		$.ajax({
			type: 'GET',
			url: urlMain,
			contentType: 'application/json',
			datatype: 'json',
			data: postData,
			async: true,
			success: function() {
				$('#dbPasswordCellInput').fadeOut('fast', function () {
					$('#dbPasswordCellInput').fadeIn('slow');
				});
			}
		});
		return false;
	});
	setFormDBMainValidateSubmitAction();
	$('#modalShowError').on('hidden.bs.modal', function () {
		$('a[href=#settings]').tab('show');
		error = undefined;
	});
	$('#modalAddRepository').on('hidden.bs.modal', function () {
		if(typeof error === 'undefined') $('a[href=#home]').tab('show');
	});
	$('#modalRemoveRepository').on('hidden.bs.modal', function () {
		if(typeof error === 'undefined') $('a[href=#home]').tab('show');
	});
	$('#refreshRepoButton').click(function() {
		var repositoryRowArea = $('#repositoryRowArea');
		if(repositoryRowArea.is(':visible')) {
			repositoryRowArea.fadeOut('fast',  function() {
				repositoryRowArea.empty('');
				updateRepositoryRowArea();
			});	
		} else {
			updateRepositoryRowArea();
		}	
	});
	$('#settingslink').click(function() {
		var mySelectedRepo = $('.selectedRow4Repo');
		if(mySelectedRepo.length == 0) {
			var mytable = $('#noRepoTable');
			mytable.find("tbody").children('tr:first').fadeIn('fast');
			mytable.find("tbody").find("tr:gt(0)").remove();
		} else {
			var mytable = $('#noRepoTable');
			mytable.find("tbody").children('tr:first').fadeIn('fast');
			mytable.find("tbody").find("tr:gt(0)").remove();
			//Hent deretter xml som svar og fyll settings siden:
			getRepositoryConfiguration(mySelectedRepo.text());
		}
	});
	$('#formNewRepo').submit(function(e) {
		e.preventDefault();
		$('#errorMessage').empty();
		var listHeading = e.target[0].value;
		var dbUser = e.target[1].value;
		var dbPassword = e.target[2].value;
		var tasteKidF = e.target[3].value;
		var tasteKidK = e.target[4].value;
		var moviePlacement = e.target[5].value;
		var urlMoviePlacement = e.target[6].value;
		var hardMoviePlacement = e.target[7].value;
		var confset = listHeading.replace(/\//g,"").replace(/\\/g,"").replace(/\:/g,"").replace(/\d+?/g,"").replace(/ +?/g,"");
		confset = confset.replace(/[^\w\s.-]/g,"");
		confset = confScriptPlacement+confset+'.conf';
		if(confset.substr(confset.length - 10) == ".conf.conf") confset = confset.substring(0, confset.length - 5);
		var settingHash = new Object();
		settingHash['listHeading'] = listHeading;
		settingHash['dbUser'] = dbUser;
		settingHash['dbPassword'] = dbPassword;
		settingHash['tasteKidF'] = tasteKidF;
		settingHash['tasteKidK'] = tasteKidK;
		settingHash['moviePlacement'] = moviePlacement;
		settingHash['urlMoviePlacement'] = urlMoviePlacement;
		settingHash['hardMoviePlacement'] = hardMoviePlacement;
		if(confset) {
			if(createConfigurationSettings(settingHash,confset)) refreshRepoList();
		}
	});
	$('#createRepoBtn').click(function() {
		$('#formNewRepo').submit();
	});
	$('table[id=noRepoTable]').hover(
	  function () {
		$(this).addClass("hover");
	  },
	  function () {
		$(this).removeClass("hover");
	  }
	)
});
function movediv() {
	$('#local_bottom_showbar').css('top', $(window).scrollTop() + $(window).height() - parseInt($('#local_bottom_showbar').css('height')) + 'px');
	$('#local_bottom_showbar').css('height',$('.local_header_showbar').css('height')).css('width', $('.local_header_showbar').css('width'));	
}
function getRepositoryConfiguration(configurationFullPath) {
	var confset = encodeURI(confScriptPlacement+configurationFullPath+'.conf');
	if(confset.substr(confset.length - 10) == ".conf.conf") confset = confset.substring(0, confset.length - 5);
	var postData = 'getWholeConfigset=' + confset;
	error = undefined;
	var moviePlacement, urlMoviePlacement, urlImagePlacement, coverCachePlacement, listHeading, dbUser, dbPassword, styleSheetPlacement;
	var tableType, currentPagePosition, movieNameOffset, updateInterval, javaScriptPlacement, sambaUsage, numberOfRecomendations, numberOfMoviesBeforeDBTakeOver;
	var youtubeEmbedString, tastekidString, neverEmbed, tasteKidF, tasteKidK, forcedTasteKidAPI;
	$.ajax({
		type: 'GET',
		url: urlMain,
		dataType: "xml",
		data: postData,
		async: false,
		success: function(xml) {
			$(xml).find('error').each(function(){
				error = $(this).text();
			});
			if(typeof error === 'undefined'){
				var mytable = $('#noRepoTable');
				mytable.find("tbody").children('tr:first').fadeOut('fast');
				var xCounter = 1;
				var colSize = 10;
				$(xml).find('configinfo').each(function(){
					moviePlacement = $(this).find('moviePlacement').text();
					mytable.find("tbody").hide().append('<tr><td>1</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Full path to where the symlinks to movies are placed\');" onMouseOut="hideMessageBox();">moviePlacement</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formInputMoviePlacement'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+moviePlacement+'"></input></div><button type="submit" class="btn" id="formInputMoviePlacement'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');
					urlMoviePlacement = $(this).find('urlMoviePlacement').text();
					mytable.find("tbody").hide().append('<tr><td>2</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Relative path from /usr/share to where the symlinks to movies are placed\');" onMouseOut="hideMessageBox();">urlMoviePlacement</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formInputUrlMoviePlacement'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+urlMoviePlacement+'"></input></div><button type="submit" class="btn" id="formInputUrlMoviePlacement'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');
					urlImagePlacement = $(this).find('urlImagePlacement').text();
					mytable.find("tbody").hide().append('<tr><td>3</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Relative path from /usr/share to where the images are placed\');" onMouseOut="hideMessageBox();">urlImagePlacement</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formInputUrlImagePlacement'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+urlImagePlacement+'"></input></div><button type="submit" class="btn" id="formInputUrlImagePlacement'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');
					coverCachePlacement = $(this).find('coverCachePlacement').text();
					mytable.find("tbody").hide().append('<tr><td>4</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Relative path from /usr/share to where the moviecovers are stored\');" onMouseOut="hideMessageBox();">coverCachePlacement</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formCoverCachePlacement'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+coverCachePlacement+'"></input></div><button type="submit" class="btn" id="formInputCoverCachePlacement'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');
					listHeading	= $(this).find('listHeading').text();	
					mytable.find("tbody").hide().append('<tr><td>5</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'States the heading and title of the movie list\');" onMouseOut="hideMessageBox();">listHeading</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formListHeading'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+listHeading+'"></input></div><button type="submit" class="btn" id="formListHeading'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');					
					dbUser = $(this).find('dbUser').text();
					mytable.find("tbody").hide().append('<tr><td>6</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets the user that the repository uses to talk to the database\');" onMouseOut="hideMessageBox();">dbUser</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formDbUser'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+dbUser+'"></input></div><button type="submit" class="btn" id="formDbUser'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');
					dbPassword = $(this).find('dbPassword').text();
					mytable.find("tbody").hide().append('<tr><td>7</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets the password for the user that this repository uses to talk to the database\');" onMouseOut="hideMessageBox();">dbPassword</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formDbPassword'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="password" class="form-control" value="'+dbPassword+'"></input></div><button type="submit" class="btn" id="formDbPassword'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');					
					styleSheetPlacement = $(this).find('styleSheetPlacement').text();					
					mytable.find("tbody").hide().append('<tr><td>8</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets the relative path from /usr/share to where the style sheets are placed for the repository web page\');" onMouseOut="hideMessageBox();">styleSheetPlacement</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formStyleSheetPlacement'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+styleSheetPlacement+'"></input></div><button type="submit" class="btn" id="formInputStyleSheetPlacement'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');					
					tableType = $(this).find('tableType').text();
					mytable.find("tbody").hide().append('<tr><td>9</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets the table size, small, medium or big\');" onMouseOut="hideMessageBox();">tableType</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formTableType'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+tableType+'"></input></div><button type="submit" class="btn" id="formInputTableType'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');
					movieNameOffset = $(this).find('movieNameOffset').text();
					mytable.find("tbody").hide().append('<tr><td>10</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets at what character the script should start reading the name for the movie from the folder name of the folder where the movie is contained\');" onMouseOut="hideMessageBox();">movieNameOffset</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formMovieNameOffset'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+movieNameOffset+'"></input></div><button type="submit" class="btn" id="formMovieNameOffset'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');					
					updateInterval = $(this).find('updateInterval').text();
					mytable.find("tbody").hide().append('<tr><td>11</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets how many days a movie can have info un-updated in the local database before a update is forced\');" onMouseOut="hideMessageBox();">updateInterval</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formUpdateInterval'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+updateInterval+'"></input></div><button type="submit" class="btn" id="formInputUpdateInterval'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');
					javaScriptPlacement = $(this).find('javaScriptPlacement').text();
					mytable.find("tbody").hide().append('<tr><td>12</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets the relative path to where the javascript files are placed\');" onMouseOut="hideMessageBox();">javaScriptPlacement</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formJavaScriptPlacement'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+javaScriptPlacement+'"></input></div><button type="submit" class="btn" id="formInputJavaScriptPlacement'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');
					sambaUsage = $(this).find('sambaUsage').text();
					mytable.find("tbody").hide().append('<tr><td>13</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets if Samba is set up and configured for the script to link to movies\');" onMouseOut="hideMessageBox();">sambaUsage</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formSambaUsage'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+sambaUsage+'"></input></div><button type="submit" class="btn" id="formInputCoverCachePlacement'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');					
					numberOfRecomendations	= $(this).find('numberOfRecomendations').text();	
					mytable.find("tbody").hide().append('<tr><td>14</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets the amount of movie recommendations in the database for each movie\');" onMouseOut="hideMessageBox();">numberOfRecomendations</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formNumberOfRecomendations'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+numberOfRecomendations+'"></input></div><button type="submit" class="btn" id="formInputNumberOfRecomendations'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');
					numberOfMoviesBeforeDBTakeOver = $(this).find('numberOfMoviesBeforeDBTakeOver').text();
					mytable.find("tbody").hide().append('<tr><td>15</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets the amount of movies read from disk before local database is attempted to be used\');" onMouseOut="hideMessageBox();">numberOfMoviesBeforeDBTakeOver</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formNumberOfMoviesBeforeDBTakeOver'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+numberOfMoviesBeforeDBTakeOver+'"></input></div><button type="submit" class="btn" id="formInputNumberOfMoviesBeforeDBTakeOver'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');					
					youtubeEmbedString = $(this).find('youtubeEmbedString').text();
					mytable.find("tbody").hide().append('<tr><td>16</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets the text that this script looks for to crawl and get YouTube trailers for the movie\');" onMouseOut="hideMessageBox();">youtubeEmbedString</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formYoutubeEmbedString'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+youtubeEmbedString+'"></input></div><button type="submit" class="btn" id="formInputYoutubeEmbedString'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');					
					tastekidString = $(this).find('tastekidString').text();
					mytable.find("tbody").hide().append('<tr><td>17</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets the text that the script looks for to crawl and get movie recomendations\');" onMouseOut="hideMessageBox();">tastekidString</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formTastekidString'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+tastekidString+'"></input></div><button type="submit" class="btn" id="formTastekidString'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');					
					neverEmbed = $(this).find('neverEmbed').text();
					mytable.find("tbody").hide().append('<tr><td>18</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets if trailers should never be embedded(recommended) or always try to be embedded into the web page\');" onMouseOut="hideMessageBox();">neverEmbed</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formNeverEmbed'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+neverEmbed+'"></input></div><button type="submit" class="btn" id="formInputNeverEmbed'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');					
					tasteKidF = $(this).find('tasteKidF').text();	
					mytable.find("tbody").hide().append('<tr><td>19</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets the username used to connect to TasteKid.com and get recommendations\');" onMouseOut="hideMessageBox();">tasteKidF</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formTasteKidF'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+tasteKidF+'"></input></div><button type="submit" class="btn" id="formInputTasteKidF'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');
					tasteKidK = $(this).find('tasteKidK').text();
					mytable.find("tbody").hide().append('<tr><td>20</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets the password used to connect to TasteKid.com and get recommendations\');" onMouseOut="hideMessageBox();">tasteKidK</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formTasteKidK'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+tasteKidK+'"></input></div><button type="submit" class="btn" id="formInputTasteKidKB'+xCounter+'tn">Set</button></form></td><tr>').fadeIn('fast');
					forcedTasteKidAPI = $(this).find('forcedTasteKidAPI').text();
					mytable.find("tbody").hide().append('<tr><td>21</td><td name="settingsNameCell" onMouseOver="displayMessageBox(\'Sets if username and password should always be used or not to get recommendations. If not always used (0), then crawling is attempted first. This may produce inaccurate scramble\');" onMouseOut="hideMessageBox();">forcedTasteKidAPI</td><td><form name="configForm" action="/movieLister/cgi-bin/movieLister.pl" method="GET" class="form-inline" id="formForcedTasteKidAPI'+xCounter+'"><div class="col-lg-'+colSize+'"><input type="text" class="form-control" value="'+forcedTasteKidAPI+'"></input></div><button type="submit" class="btn" id="formInputForcedTasteKidAPI'+xCounter+'Btn">Set</button></form></td><tr>').fadeIn('fast');
					setConfigurationUpdateButtons(xCounter, confset);
					xCounter++;	
				});					
				error = 0;
			}
		}
	});
	if(error) $(":animated").promise().done(function() {showError(error);});
				
	return (error ? 0 : 1);
}
function setConfigurationUpdateButtons(xCounter, confset) {
	$('form[name="configForm"]').submit(function(e) {
		e.preventDefault();
		var setting = e.target[0].value;
		var settingHash = new Object();
		var settingString = e.currentTarget.id.substring(4).substring(0, e.currentTarget.id.substring(4).length - 1);
		var settingName = settingString.charAt(0).toLowerCase(); 
		settingName = settingName + settingString.slice(1);
		settingHash[settingName] = setting;
		if(setConfigurationSettings(settingHash, confset)) {
			$('#'+e.currentTarget.id).fadeOut('fast').fadeIn('slow');
		} else {
			$('#modalShowError').modal('hide');
			$('#modalShowError').modal('show');
		}
	});
}
function setFormDBMainValidateSubmitAction() {
	$('#formdbMainValidateUpdate').submit(function() {
		$('#errorMessage').empty();
		validateMainConfiguration();
		return false;
	});
}
function setMainConfigurationConfigDoneStatus(status) {
	var confset = mainConfigSet;
	var hashvalues = {configDone:status};
	var postData = 'JSONconfigset=' + encodeURIComponent(JSON.stringify(hashvalues))+'&setRepository='+encodeURIComponent(confset);
	$.ajax({
		type: 'GET',
		url: urlMain,
		contentType: 'application/json',
		datatype: 'json',
		data: postData,
		async: true,
		success: function() {
			getMainConfig();
		}
	});
}
function createConfigurationSettings(settings, confset) {
	error = undefined;
	if(settings && confset) {
		var hashvalues = '{';
		for (var key in settings) {
			hashvalues += '"' + key + '":"' + settings[key]+'",';
		}
		hashvalues = hashvalues.substring(0, hashvalues.length - 1) + '}';
		hashvalues = jQuery.parseJSON(hashvalues);
		var jsonText = JSON.stringify(hashvalues);
		var postData = 'JSONconfigset=' + jsonText +'&setRepository='+encodeURIComponent(confset) + '&createRepo=1';
		$.ajax({
			type: 'GET',
			url: urlMain,
			contentType: 'application/json',
			datatype: 'json',
			data: postData,
			async: false,
			success: function(xml) {
				$(xml).find('error').each(function(){
					error = $(this).text();
				});
			}
		});
		if(typeof  error === 'undefined') updateRepoList();
		$('#modalAddRepository').modal('hide');
		if(typeof error !== 'undefined'){
			if(error) $(":animated").promise().done(function() {showError(error);});
		}
	}
	return (typeof  error === 'undefined');
}
function removeRepository(confset) {
	error = undefined;
	if(confset) {
		var postData = 'deleteRepository='+encodeURIComponent(confset);
		$.ajax({
			type: 'GET',
			url: urlMain,
			dataType: 'xml',
			data: postData,
			async: false,
			success: function(xml) {
				$(xml).find('error').each(function(){
					error = $(this).text();
				});
			}
		});
		refreshRepoList();
		if(typeof error !== 'undefined'){
			if(error) $(":animated").promise().done(function() {showError(error);});
		}
	}
}
function setConfigurationSettings(settings, confset) {
	error = undefined;
	if(settings && confset) {
		var hashvalues = '{';
		for (var key in settings) {
			hashvalues += '"' + key + '":"' + settings[key]+'",';
		}
		hashvalues = hashvalues.substring(0, hashvalues.length - 1) + '}';
		hashvalues = jQuery.parseJSON(hashvalues);
		var jsonText = JSON.stringify(hashvalues);
		if(confset.substr(confset.length - 10) == ".conf.conf") confset = confset.substring(0, confset.length - 5);
		var postData = 'JSONconfigset=' + jsonText +'&setRepository='+encodeURIComponent(confset);
		$.ajax({
			type: 'GET',
			url: urlMain,
			contentType: 'application/json',
			datatype: 'json',
			data: postData,
			async: true,
			success: function(xml) {
				$(xml).find('error').each(function(){
					error = $(this).text();
				});
			}
		});
		if(typeof error === 'undefined'){
			var mytable = $('#noRepoTable');
			mytable.find("tbody").find("tr:gt(0)").fadeOut('slow', function() {
				mytable.find("tbody").children('tr:first').fadeIn('fast');
				$(this).remove();
			});
			$('html,body').animate({ scrollTop: 0 }, 'slow', function () {					
				getRepositoryConfiguration($('.selectedRow4Repo').text());
			});
		} else {
			if(error) $(":animated").promise().done(function() {showError(error);});
		}
	}
	return (error ? 0 : 1);
}
function setSpan4RepoClickAction() {
	$('.spanRow4Repo').unbind("click");
	$('.spanRow4Repo').click(function() {
		var clickedButton = $(this);
		if(clickedButton.hasClass('selectedRow4Repo')) {
			clickedButton.removeClass('selectedRow4Repo');
			clickedButton.addClass('spanRow4Repo');
		} else {
			$('.selectedRow4Repo').each(function() {
				$(this).removeClass('selectedRow4Repo');
				$(this).addClass('spanRow4Repo');
			});
			clickedButton.removeClass('spanRow4Repo');
			clickedButton.addClass('selectedRow4Repo');
		}
	});
}
function updateRepositoryRowArea() {
	var repositoryRowArea = $('#repositoryRowArea');
	var initialInitiateMessage = $('#initialInitiateMessage');
	if(validateMainConfiguration()) {
		updateRepoList();	
		if($('#repositoryRowArea > div').size() < 1) {
			if(initialInitiateMessage.is(':hidden')) initialInitiateMessage.fadeIn('slow');
			if(repositoryRowArea.is(':visible')) repositoryRowArea.fadeOut('fast');
		} else {
			if(repositoryRowArea.is(':hidden')) repositoryRowArea.fadeIn('fast');
			if($('#initialInitiateMessage').is(":visible")) $('#initialInitiateMessage').hide();
		}
	} else {
		if(initialInitiateMessage.is(':hidden')) initialInitiateMessage.fadeIn('fast');
		if(repositoryRowArea.is(':visible')) repositoryRowArea.fadeOut('fast');
	}
}
function updateRepoList() {
	var confset, confname, state, validity, error, comment;
	var url = urlMain;
	$.ajax({
		type: 'GET',
		url: url,
		data: 'getRepositories=1',
		dataType: "xml",
		async: false,
		success: function(xml) {
			$(xml).find('error').each(function(){
				error = $(this).text();
			});
			if(typeof error === 'undefined'){
				$(xml).find('config').each(function(){
					confset = $(this).find('confset').text();
					confname = $(this).find('confname').text();
					state = $(this).find('state').text();
					validity = $(this).find('validity').text();
					comment	= $(this).find('comment').text();			
					if(validity) {
						addRepositoryToHomeTab(confset, confname, state, comment);					
					} else {
						error = "Repository " + confname + " is registered but does not exist on server.";
					}
				});
			}
		}
	});
	if(error) if(error) $(":animated").promise().done(function() {showError(error);});
}
function refreshRepoList() {
	var repositoryRowArea = $('#repositoryRowArea');
	repositoryRowArea.fadeOut('fast',  function() {
		repositoryRowArea.empty('');
		updateRepositoryRowArea();
	});
}
function getMainConfig() {
	var dbUser, dbPassword, configDone, error;
	var url = urlMain;
	$.ajax({
		type: 'GET',
		url: url,
		data: 'getMainConfigset=1',
		dataType: "xml",
		async: false,
		success: function(xml) {
			$(xml).find('error').each(function(){
				error = $(this).text();
			});
			if(typeof error === 'undefined'){
				$(xml).find('configinfo').each(function(){
					dbUser = $(this).find('dbUser').text();
					dbPassword = $(this).find('dbPassword').text();
					configDone = $(this).find('configDone').text();
					if(dbPassword) $('#dbPasswordCellInput').val(dbPassword);
					if(dbUser) $('#dbUserCellInput').val(dbUser);
					if(configDone.toLowerCase() != "yes") {
						error = "Main config is not set up in a working state. Please setup the main configuration via the settings tab.";
					}
				});
			}
		}
	});
	if(error) $(":animated").promise().done(function() {showError(error);});
	return (error ? 0 : 1);
}
function showError(errorMessage) {
	$('#mdlErroMessageLabel').text('Warning: Error encountered!');
	$('#errorMessage').text(errorMessage);
	$('#modalShowErrorLink').trigger('click');
	//$('#modalShowError').modal('show');
	//$('#showErrorTab').fadeIn('fast');
}
function addRepositoryToHomeTab(confset, confname, state, comment) {
	if(!(confset.indexOf("master-config.conf") >= 0)) {
		var scriptName = confset.split('/')[confset.split('/').length-1];
		if(scriptName.substr(scriptName.length - 10) == ".conf.conf") scriptName = scriptName.substring(0, scriptName.length - 5);
		scriptName = scriptName.replace(/conf/g,"pl");
		var url = encodeURI(window.location.protocol + "//" + window.location.host + "/movieLister/cgi-bin/" + scriptName);
		if($('#initialInitiateMessage').is(":visible")) $('#initialInitiateMessage').hide();
		//confname = confname.replace(/\//g,"");
		//confname = confname.replace(/\\/g,"");
		var friendlyConfname = confname.replace(/\//g,"").replace(/\\/g,"").replace(/\:/g,"").replace(/\./g,"");
		if(friendlyConfname.substr(friendlyConfname.length - 4) == "conf") friendlyConfname = friendlyConfname.substring(0, friendlyConfname.length - 4);
		var repositoryRow = '<div class="row-fluid" id="' + friendlyConfname + 'message">' +
							'<div class="span3 spanRow4Repo">' + confname + (state > 0 ? '' : ' is disabled') + '</div>' +
							'<div class="span9 spanRow4Comment"><form action="' + urlMain + '" method="Get" class="form-inline" id="form'+friendlyConfname+'"><div class="col-lg-8"><input type="text" name="updateRepoComment" id="updateRepoComment'+friendlyConfname+'" ' + ( comment ? ' value="' + comment + '" ' : 'placeholder="Enter repository description here" ') + 'class="form-control search-query" /></div><input type="hidden" name="confset" id="confset'+friendlyConfname+'" value="'+ confset.split('/')[confset.split('/').length-1]+ '">&nbsp;&nbsp;<button type="submit" class="btn btn-primary" id="updateCommentBTN' + friendlyConfname + '">Update Comment</button>&nbsp;&nbsp;&nbsp;<button onclick="return false;" class="btn btn-default btn-white" id="showPageBTN' + friendlyConfname + '">Show Contents</button>&nbsp;&nbsp;&nbsp;<button onclick="return false;" class="btn btn-default btn-white" id="removePageBTN' + friendlyConfname + '">Remove</button></form></div>' +
							'</div><br/>';
		$(repositoryRow).hide();
		$('#repositoryRowArea').append(repositoryRow).fadeIn('slow');
		$('#showPageBTN' + friendlyConfname).click(function() {
			openLister.show();
			window.location = url;
			return false;
		});
		$('#removePageBTN' + friendlyConfname).click(function() {
			removeRepository(confname);
			return false;
		});
		$('#form'+friendlyConfname).submit(function() {			
			var comment = $('input[id=updateRepoComment'+friendlyConfname+']').val();
			var confset = $('input[id=confset'+friendlyConfname+']').val();
			error = undefined;
			$.ajax({
				type: 'GET',
				url: urlMain,
				data: 'updateRepoComment='+comment+'&confset='+confset,
				dataType: "xml",
				async: false,
				success: function(xml) {
					$(xml).find('error').each(function(){
						error = $(this).text();
					});
					if(typeof error === 'undefined'){
						//All OK - do nothing.
						$('#updateRepoComment'+friendlyConfname).fadeOut('fast', function () {
							$('#updateRepoComment'+friendlyConfname).text(comment);
							$('#updateRepoComment'+friendlyConfname).fadeIn('fast');
						});
					}
				}
			});
			if(error) $(":animated").promise().done(function() {showError(error);});
			return false;
		});
		setSpan4RepoClickAction();
	}
}
function validateMainConfiguration() {
	var postData = 'validateMainConfiguration=1';
	error = undefined;
	$.ajax({
		type: 'GET',
		url: urlMain,
		dataType: "xml",
		data: postData,
		async: false,
		success: function(xml) {
				$(xml).find('error').each(function(){
				error = $(this).text();
			});
			var myFormButton = $('#formdbValidateUpdateBtn');
			if(typeof error === 'undefined'){
				if(myFormButton.hasClass('btn-primary')) myFormButton.removeClass('btn-primary');
				if(!myFormButton.hasClass('btn-success')) myFormButton.addClass('btn-success');
				if(myFormButton.hasClass('btn-danger')) myFormButton.removeClass('btn-danger');
				$('#formdbValidateUpdateError').text('Success!').fadeOut('fast');
				$('#formdbValidateUpdateErrorLabel').fadeOut('fast');
				$('#formdbValidateUpdateSuccessLabel').show().fadeOut('fast').fadeIn('slow');
				setMainConfigurationConfigDoneStatus('yes');
				error = 0;
			} else {
				if(myFormButton.hasClass('btn-primary')) myFormButton.removeClass('btn-primary');
				if(!myFormButton.hasClass('btn-danger')) myFormButton.addClass('btn-danger');
				if(myFormButton.hasClass('btn-success')) myFormButton.removeClass('btn-success');
				$('#formdbValidateUpdateError').text(error).show().fadeOut('fast').fadeIn('slow');
				$('#formdbValidateUpdateErrorLabel').show().fadeOut('fast').fadeIn('slow');
				$('#formdbValidateUpdateSuccessLabel').fadeOut('fast');
				setMainConfigurationConfigDoneStatus('no');
			}
		}
	});
	if(error) $(":animated").promise().done(function() {showError(error);});
	return (error ? 0 : 1);
}
function escapeString(myString) {
	return myString.replace(/"/g, '&#34;').replace(/'/g, '&#39;').replace(/&/g, '&#38;').replace(/>/g, '&#62;').replace(/</g, '&#60;').replace(/%/g, '&#37;').replace(/\=/g, '&#61;').replace(/\?/g, '&#63;');
}
function displayMessageBox(message) {
    $('#lowerRightCornerMessageBox').text('  ' + message + '  ').fadeIn('fast');
}
function hideMessageBox() {
    var messageBox = $('#lowerRightCornerMessageBox');
    var messageTableHover = false;
    $('table[id=noRepoTable]').each(function() {
        if ($(this).hasClass('hover')) messageTableHover = true;
    });
    if (messageBox.is(':visible') && !messageTableHover) messageBox.fadeOut('slow');
}
function trimString(str) {
    str = str.replace(/^\s+/, '');
    for (var i = str.length - 1; i >= 0; i--) {
        if (/\S/.test(str.charAt(i))) {
            str = str.substring(0, i + 1);
            break;
        }
    }
    return str;
}