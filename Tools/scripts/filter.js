if(WScript.Arguments.length == 0) WScript.quit(-1);
var fso = new ActiveXObject("Scripting.FileSystemObject");
var WshShell = new ActiveXObject("WScript.Shell");
var tmppath = WshShell.Environment("Process").Item("tmppath");
if(tmppath == "" || !fso.FolderExists(tmppath))
	WScript.Quit(1);
var re = new RegExp("[^a-zà-ÿ¸¨0-9_:\\.,~@#$\\-+=\\\\/{}\\[\\]'`? ]","ig");
var rd = new RegExp("[\\u2191]","ig");
var rp = new RegExp("\"","ig");
var basepath, basepathdos, ret, outfirst;
var argn, outdirorig, outdir, isstdin;

outdir = ""; outdirorig = "";
isstdin = "";
argn = WScript.Arguments.named;

if(argn.Exists("Outdir")) {
	outdirorig = argn.Item("Outdir");
	if(outdirorig.match(rd) || outdirorig.match(re)) {
		WScript.StdErr.WriteLine(sDOS2Win(" " + outdirorig,true));
		WScript.quit(-1);
	}
	if (outdirorig.toUpperCase() == "FALSE")
		outdirorig = "";
	else {
		outdirorig = fso.GetAbsolutePathName(outdirorig);
		if(!fso.FolderExists(outdirorig)) if(CreateTree(outdirorig)) WScript.quit(-3);
	}
}

var JPG = 0, PNG = 1, GIF = 2;
var rfile = new Array(
	{name: "JPG", ri: new RegExp("\\.jp(g|eg?)$","ig"), iswork: false, isfirst: false},
	{name: "PNG", ri: new RegExp("\\.png$","ig"), iswork: false, isfirst: false},
	{name: "GIF", ri: new RegExp("\\.gif$","ig"), iswork: false, isfirst: false});
var num;

for(var i in rfile) {
	if(argn.Exists(rfile[i].name)) if(argn.Item(rfile[i].name).length > 0) {
		num = parseInt(argn.Item(rfile[i].name));
		if(!isNaN(num) && num>=1 && num<=3)
			rfile[i].iswork=true;
	}
}

if (!rfile[JPG].iswork && !rfile[PNG].iswork && !rfile[GIF].iswork) WScript.quit(0);
if(argn.Exists("IsStdIn")) isstdin = argn.Item("IsStdIn").toUpperCase();
ret = 0;

if(isstdin=="YES") {
	while (!WScript.StdIn.AtEndOfStream) {
		basepath = WScript.StdIn.ReadLine().replace(rp,"");
		WorkBasepath();
	}

} else {
	for(i=0;i<WScript.Arguments.unnamed.count;++i) {
		basepath = WScript.Arguments.unnamed(i);
		WorkBasepath();
	}
}

WScript.quit(ret);

function WorkBasepath() {
	if(basepath.match(rd)) {
		WScript.StdErr.WriteLine(sDOS2Win(" " + basepath,true));
		return 0;
	}
	basepath = fso.GetAbsolutePathName(basepath);
	if(fso.FileExists(basepath) && FileMatch(basepath)) {
		ret += workv(basepath);
	} else if(fso.FolderExists(basepath)) {
		if(outdirorig!="") {
			outfirst = fso.GetBaseName(basepath);
			if(fso.GetExtensionName(basepath)!="") outfirst += "." + fso.GetExtensionName(basepath);
			outfirst = getFolderName(fso.BuildPath(outdirorig,outfirst));
			if(outfirst=="") {
				WScript.StdErr.WriteLine(" " + sDOS2Win(basepath,true));
				return 0;
			}
		}
		ret += DirWork(basepath);
	}
}

function DirWork(dir) {
	var f, fc, ret;
	ret = 0;
	f = fso.GetFolder(dir);
	fc = new Enumerator(f.files);
	for (; !fc.atEnd(); fc.moveNext()) {
		if(FileMatch(fc.item().Path)) 
			ret += workv(fc.item().Path);
	}
	fc = new Enumerator(f.SubFolders);
	for (; !fc.atEnd(); fc.moveNext()) {
		ret += DirWork(fc.item().Path);
	}
	return(ret);
}

function FileMatch(fname) {
	for(var i in rfile)
		if(rfile[i].iswork && fname.match(rfile[i].ri)) {
			if(!rfile[i].isfirst) {
				var a = fso.CreateTextFile(fso.GetAbsolutePathName(tmppath+"\\"+rfile[i].name+".flag"), true);
				a.WriteLine("Yes");
				a.Close();
				rfile[i].isfirst = true;
			}
			return true;
		}
	return false;
}

function CreateTree(p) {
	p = fso.GetAbsolutePathName(p);
	if(fso.FileExists(p)) return(-1);
	if(fso.FolderExists(p)) return(0);
	var owner = fso.GetParentFolderName(p);
	if(!fso.FolderExists(owner))
		if(CreateTree(owner)) return(-2);
	fso.CreateFolder(p);
	return(0);
}

function workv(str) {
	var p, tp, tf;
	if(str.match(rd)) {
		WScript.StdErr.WriteLine(" " + sDOS2Win(basepath,true));
		return 0;
	}
	p = fso.GetParentFolderName(str);
	if(outdirorig.toUpperCase() == fso.GetAbsolutePathName(p).toUpperCase()) 
		outdir = "";
	else
		outdir = outdirorig;
	if(!str.match(re) && !str.match(rd)) {
		tf = fso.GetFileName(str);
		if(outdir!="") {
			if(str.toUpperCase()==basepath.toUpperCase()) {
				tp = outdir;
			} else {
				tp = outfirst + p.substr(basepath.length);
			}
			tf = fso.GetFileName(getFileName(fso.BuildPath(tp,tf)));
		} else {
			tp = p;
		}
		WScript.StdOut.WriteLine(sDOS2Win(str + "\t" + fso.BuildPath(tp,tf),true));
		return 1;
	} else {
		WScript.StdErr.WriteLine(" " + sDOS2Win(str,true));
		return 0;
	}
}

function checkFileName(fn) {
	if (fn.match(re)) {
		return fso.GetBaseName(fso.GetTempName()) + "." + fso.GetExtensionName(fn);
	}
	return fn;
}

function filecopy(source,target) {
	if(!fso.FileExists(source)) return "";
	var name = getFileName(target);
	if(name=="") return "";
	fso.CopyFile(source,name,true);
	return name;
}

function filemove(source,target) {
	if(!fso.FileExists(source)) return "";
	var name = getFileName(target);
	if(name=="") return "";
	fso.MoveFile(source,name);
	return name;
}

function getFileName(fn) {
	if(!fso.FileExists(fn)) return fn;
	var ext, name, i;
	ext = fso.GetExtensionName(fn);
	name = fso.GetParentFolderName(fn) + "\\" + fso.GetBaseName(fn);
	i = 1;
	while(fso.FileExists(name+"-"+padleft(i,4,"0")+"."+ext) && i<10000) ++i;
	if(i>9999) return "";
	return name+"-"+padleft(i,4,"0")+"."+ext;
}

function getFolderName(fn) {
	if(!fso.FolderExists(fn)) return fn;
	var ext, name, i;
	ext = fso.GetExtensionName(fn);
	if(ext!="") ext = "." + ext;
	name = fso.GetParentFolderName(fn) + "\\" + fso.GetBaseName(fn);
	i = 1;
	while(fso.FolderExists(name+"-"+padleft(i,4,"0")+ext) && i<10000) ++i;
	if(i>9999) return "";
	return name+"-"+padleft(i,4,"0")+ext;
}

function padleft(s,l,c) {
	while(s.toString().length<l) s = c + s;
	return s;
}

function GetCharCodeHexString(sText) {
	var j, str1="";
	for(j=0;j<sText.length;++j) str1 += " " + sText.charCodeAt(j).toString(16);
	return str1.substr(1);
}

function sDOS2Win(sText, bInsideOut) {
	var aCharsets = ["windows-1251", "cp866"];
	sText += "";
	bInsideOut = bInsideOut ? 1 : 0;
	with (new ActiveXObject("ADODB.Stream")) {
		type = 2; 
		mode = 3;
		charset = aCharsets[bInsideOut];
		open();
		writeText(sText);
		position = 0;
		charset = aCharsets[1 - bInsideOut];
		return readText();
	}
}
