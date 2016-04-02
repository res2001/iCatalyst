if(WScript.Arguments.length == 0) WScript.quit(-1);
var fso = new ActiveXObject("Scripting.FileSystemObject");
var re = new RegExp("[^a-zà-ÿ¸¨0-9_:\\.,~@#$\\-+=\\\\/{}\\[\\]'`? ]","ig");
var rd = new RegExp("[\\u2191]","ig");
var basepath;
var argn, outdirorig, perr, params;
var WIN2DOS = 1, DOS2WIN = 0;
params = "";
outdirorig = "";
perr = "";
argn = WScript.Arguments.named;

var JPG = 0, PNG = 1, GIF = 2, num;
var rfile = new Array(
	{name: "JPG", ri: new RegExp("\\.jp(g|eg?)$","ig"),	mask: "*.jpg;*.jpe?",	opt: -1, max: 3},
	{name: "PNG", ri: new RegExp("\\.png$","ig"), 		mask: "*.png",		opt: -1, max: 2},
	{name: "GIF", ri: new RegExp("\\.gif$","ig"), 		mask: "*.gif",		opt: -1, max: 1}
);

if(argn.Exists("Outdir")) {
	outdirorig = argn.Item("Outdir");
	if((outdirorig.toUpperCase() != "FALSE") && (outdirorig.toUpperCase() != "TRUE")) {
		outdirorig = fso.GetAbsolutePathName(outdirorig);
		if(outdirorig.match(rd) || outdirorig.match(re)) {
			echoerr(" " + outdirorig, WIN2DOS);
			perr = "Outdir;";
		}
	}
}

if(argn.Exists(rfile[JPG].name) && argn.Item(rfile[JPG].name).length > 0) {
	num = parseInt(argn.Item(rfile[JPG].name));
	if(!isNaN(num) && num>=0 && num<=rfile[JPG].max)
		rfile[JPG].opt = num;
	else perr += "JPG;"
}

if(argn.Exists(rfile[PNG].name) && argn.Item(rfile[PNG].name).length > 0) {
	num = parseInt(argn.Item(rfile[PNG].name));
	if(!isNaN(num) && num>=0 && num<=rfile[PNG].max)
		rfile[PNG].opt = num;
	else perr += "PNG;"
}

if(argn.Exists(rfile[GIF].name) && argn.Item(rfile[GIF].name).length > 0) {
	num = parseInt(argn.Item(rfile[GIF].name));
	if(!isNaN(num) && num>=0 && num<=rfile[GIF].max)
		rfile[GIF].opt = num;
	else perr += "GIF;"
}

if(rfile[JPG].opt > 0 || rfile[PNG].opt > 0 || rfile[GIF].opt > 0) {
	if(rfile[JPG].opt == -1) rfile[JPG].opt = 0;
	if(rfile[PNG].opt == -1) rfile[PNG].opt = 0;
	if(rfile[GIF].opt == -1) rfile[GIF].opt = 0;
}

for(i=0;i<WScript.Arguments.unnamed.count;++i) {
	basepath = WorkBasepath(WScript.Arguments.unnamed(i));
	if(basepath != "") params += "\"" + basepath + "\" ";
}

if(perr != "")			echo("perr="+perr);
if(rfile[JPG].opt != -1)	echo("jpeg="+rfile[JPG].opt);
if(rfile[PNG].opt != -1)	echo("png="+rfile[PNG].opt);
if(rfile[GIF].opt != -1)	echo("gif="+rfile[GIF].opt);
if(outdirorig != "")		echo("outdir="+outdirorig, WIN2DOS);
if(params != "")		echo("params="+params, WIN2DOS);
WScript.quit(0);

function WorkBasepath(basepath) {
	if(basepath.match(rd)) {
		echoerr(basepath, WIN2DOS);
		return "";
	}
	basepath = fso.GetAbsolutePathName(basepath);
	if(!basepath.match(re)) {
		if(fso.FileExists(basepath) && FileMatch(basepath))
			return "f"+basepath;
		if(fso.FolderExists(basepath))
			return "d"+basepath;
	}
	echoerr(basepath, WIN2DOS);
	return "";
}

function FileMatch(fname) {
	for(var i in rfile)
		if(rfile[i].opt != 0 && fname.match(rfile[i].ri))
			return true;
	return false;
}

function echo(str, wd) {
	if(arguments.length == 1)
		WScript.StdOut.WriteLine(str);
	else
		WScript.StdOut.WriteLine(sDOS2WIN(str,wd));
}

function echoerr(str, wd) {
	if(arguments.length == 1)
		WScript.StdErr.WriteLine(" " + str);
	else
		WScript.StdErr.WriteLine(" " + sDOS2WIN(str,wd));
}

function sDOS2WIN(sText, InsideOut) {
	var aCharsets = ["windows-1251", "cp866"];
	//sText += "";
	//bInsideOut = bInsideOut ? 1 : 0;
	with (new ActiveXObject("ADODB.Stream")) {
		type = 2; 
		mode = 3;
		charset = aCharsets[InsideOut];
		open();
		writeText(sText);
		position = 0;
		charset = aCharsets[1 - InsideOut];
		return readText();
	}
}
