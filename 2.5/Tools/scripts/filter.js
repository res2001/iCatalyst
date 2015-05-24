/*
Выводит в stdout список файлов по следующим правилам.

В параметрах или в stdin (см.именованные параметры) передаются пути к папкам и/или файлам.
Переданные имена анализируются на существование в файловой системе. Если папки/файла не существует,
то данный параметр игнорируется и в stderr выводится полный абсолютный путь к папке/файлу.
Если в параметре передан путь к папке, то в этой папке в дальнейшую обрабатку
поступает каждый файл, включая подпапки. Все пути преобразуются в полный абсолютный путь к файлу.

Путь к каталогу назначения (см./Outdir) и обрабатываемый файл проверяются на соответствие RegExp(rd) 
для обнаружения спец.символов в именах файлов/каталогов, с которыми не корректно работают 
объекты FSO. Такие файлы/каталоги пропускаются и в stderr выводится полный абсолютный путь к папке/файлу.
Если спец.символ обнаружен в пути к каталогу назначения, то скрипт завершается без обработки и в 
stderr выводится полный абсолютный путь к каталогу назначения.

Полный путь к файлу делится на путь и имя файла и по отдельности проверяется соответствие 
RegExp'у (re) на содержание в пути или имени спец.символов.

Если нет соответствия RegExpу, то файл копируется в outdir (см.именованные параметры) и
в stdout выводится полный абсолютный путь к скопированному файлу.

Если в пути/имени файла найдено соответствие, то в stderr пишется полный абсолютный путь к файлу.

При задании путей, копирование файлов происходит с сохранением структуры каталогов относительно заданного.
При копировании файлов/каталогов, если в каталоге назначения уже существует файл/каталог с таким 
же имененм, то к имени копируемого файла/каталога добавляется текущий номер в формате:
<имя файла/каталога>-NNNN.<расширение файла/каталога>

Именованные параметры. 
Кроме путей и имен файлов могут быть переданы следующие именованные параметры:
/Outdir:<путь к каталогу назначения>	- в этот каталог будут копироаться файлы, если не
	задан, то файлы никуда не копируются и обрабатываются на месте. 
/IsStdIn:yes	- если задан, то пути/имена файлов читаются из stdin, а не из параметров.
/JPG:yes	- анализировать файлы jpg
/PNG:yes	- анализировать файлы png
*/

if(WScript.Arguments.length == 0) WScript.quit(-1);
var fso = new ActiveXObject("Scripting.FileSystemObject");
var re = new RegExp("[^a-zа-яёЁ0-9_:\\.,~@#$\\-+=\\\\/{}\\[\\]'`? ]","ig");
//rd - RegExp для неподдерживаемых FSO символов: 
// - \u2191
var rd = new RegExp("[\\u2191]","ig");
var rp = new RegExp("\"","ig");
var ri;
//var rslesh = new RegExp("\\\\","ig");
var basepath, basepathdos, ret, outfirst;
var argn, outdirorig, outdir, isstdin;
outdir = ""; outdirorig = "";
isstdin = "";
argn = WScript.Arguments.named;
if(argn.Exists("Outdir")) {
	outdirorig = argn.Item("Outdir");
//	WScript.echo(outdirorig.match(re));
	if(outdirorig.match(rd) || outdirorig.match(re)) {
		WScript.StdErr.WriteLine(sDOS2Win(" " + outdirorig,true));
		WScript.quit(-1);
	}
	if (outdirorig.toUpperCase() == "TRUE") 
		outdirorig = "";
	else {
		outdirorig = fso.GetAbsolutePathName(outdirorig);
		if(!fso.FolderExists(outdirorig)) if(CreateTree(outdirorig)) WScript.quit(-3);
	}
}	

var str = "", isjpg = false, ispng = false, isgif = false, num;
if(argn.Exists("JPG")) if(argn.Item("JPG").length > 0) {
	num = parseInt(argn.Item("JPG"));
	if(!isNaN(num) && num>=1 && num<=3) {
		isjpg=true;
		str = "|jp(g|e|eg)";
}}
if(argn.Exists("PNG")) if(argn.Item("PNG").length > 0) {
	num = parseInt(argn.Item("PNG"));
	if(!isNaN(num) && num>=1 && num<=2) {
		ispng=true;
		str += "|png";
}}
if(argn.Exists("GIF")) if(argn.Item("GIF").length > 0) {
	num = parseInt(argn.Item("GIF"));
	if(!isNaN(num) && num==1) {
		isgif=true;
		str += "|gif";
}}
if (!isjpg && !ispng && ! isgif) WScript.quit(0);
ri = new RegExp("\\.("+str.substr(1)+")$","ig");
if(argn.Exists("IsStdIn")) isstdin = argn.Item("IsStdIn").toUpperCase();
ret = 0;
if(isstdin=="YES") {
	while (!WScript.StdIn.AtEndOfStream) {
//		str = sDOS2Win(WScript.StdIn.ReadLine(),false);
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
//	WScript.echo(basepath);
//	WScript.echo(GetCharCodeHexString(basepath));
	if(basepath.match(rd)) {
		WScript.StdErr.WriteLine(sDOS2Win(" " + basepath,true));
		return 0;
	}
	basepath = fso.GetAbsolutePathName(basepath);
	if(fso.FileExists(basepath) && basepath.match(ri)) {
		ret += workv(basepath);
	} else if(fso.FolderExists(basepath)) {
		if(outdirorig!="") {
			//2.1.выделяем последний каталог из базового каталога и назначаем ему 
			//уникальное имя в outdir
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

/*
Рекурсивный обход каталогов переданного в параметре главного каталога
с обработкой всех файлов.
*/
function DirWork(dir) {
	var f, fc, ret;
	ret = 0;
	f = fso.GetFolder(dir);
	fc = new Enumerator(f.files);
	for (; !fc.atEnd(); fc.moveNext()) {
		if(fc.item().Path.match(ri)) ret += workv(fc.item().Path);
	}
	fc = new Enumerator(f.SubFolders);
	for (; !fc.atEnd(); fc.moveNext()) {
		ret += DirWork(fc.item().Path);
	}
	return(ret);
}

/*
Рекурсивная функция, создает путь, заданный в параметре.
Если все прошло успешно, то возвращает 0, иначе - значения <0
*/
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

/*
Обрабатывает полный путь к файлу, переданный в параметре по алгоритму описанному в шапке.
*/
function work(str) {
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
			//1.Если базовый каталог == обрабатываемому файлу
			if(str.toUpperCase()==basepath.toUpperCase()) {
				//1.1.Копируем обрабатываемый файл в outdir
				tp = outdir;
			//2.Иначе:
			} else {
				//2.2.вырезаем из p базовый каталог и добавляем к оставшейся части 
				//	с права, то что получилось в 2.1.
				tp = outfirst + p.substr(basepath.length);
				//2.3.Создаем в outdir структуру каталогов такую же как в п.2.2
				if(CreateTree(tp)) {
					WScript.StdErr.WriteLine(" " + sDOS2Win(str,true));
					return 0;
				}
				//2.4.Копируем файл по созданному в п.2.3. пути
			}
			filecopy(str,fso.BuildPath(tp,tf));
		} else {
			tp = p;
		}
		WScript.StdOut.WriteLine(sDOS2Win(fso.BuildPath(tp,tf),true));
		return 1;
	} else {
		WScript.StdErr.WriteLine(" " + sDOS2Win(str,true));
		return 0;
	}
}


/*
Обрабатывает полный путь к файлу, переданный в параметре по алгоритму описанному в шапке.
То же что и work, но файлы не копируются в каталог назначения и дерево назначения не строится.
Вместо этого в stdin выводится:
<полный путь к целевому файлу>	<полный путь к исходящему файлу>
*/
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
			//1.Если базовый каталог == обрабатываемому файлу
			if(str.toUpperCase()==basepath.toUpperCase()) {
				//1.1.Копируем обрабатываемый файл в outdir
				tp = outdir;
			//2.Иначе:
			} else {
				//2.2.вырезаем из p базовый каталог и добавляем к оставшейся части 
				//	с права, то что получилось в 2.1.
				tp = outfirst + p.substr(basepath.length);
				//2.3.Создаем в outdir структуру каталогов такую же как в п.2.2
/*				if(CreateTree(tp)) {
					WScript.StdErr.WriteLine(" " + sDOS2Win(str,true));
					return 0;
				}
*/
				//2.4.Копируем файл по созданному в п.2.3. пути
			}
//			filecopy(str,fso.BuildPath(tp,tf));
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


/*
Проверяет переданное в параметре имя файла на соответствие RegExp(re), если соответствие найдено,
то возвращает временное имя файла с тем же расширением.
Если соответствие не найдено, возвращается то же самое имя файла.
*/
function checkFileName(fn) {
	if (fn.match(re)) {
		return fso.GetBaseName(fso.GetTempName()) + "." + fso.GetExtensionName(fn);
	}
	return fn;
}

/*
Копирует файл source в target. Если файл таргет уже существует, то к имени target добавляется 
порядковый номер файла в формате:
<имя target>-NNNN.<расширение target>
Возврат: имя скопированного файла, если не удачно, то пустая строка.
*/
function filecopy(source,target) {
	if(!fso.FileExists(source)) return "";
	var name = getFileName(target);
	if(name=="") return "";
	fso.CopyFile(source,name,true);
	return name;
}

/*
Перемещает/переименовывает файл source в target. Если файл таргет уже существует, то к имени 
target добавляется порядковый номер файла в формате:
<имя target>-NNNN.<расширение target>
Возврат: имя скопированного файла, если не удачно, то пустая строка.
*/
function filemove(source,target) {
	if(!fso.FileExists(source)) return "";
	var name = getFileName(target);
	if(name=="") return "";
	fso.MoveFile(source,name);
	return name;
}


/*
Возвращает уникальное имя файла, переданного в параметре.
Если файла не существует, возвращается то же самое имя.
Если файл существует к имени файла добавляется порядковый номер в формате:
<имя target>-NNNN.<расширение target>
Возврат: уникальное имя файла.
*/
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

/*
Возвращает уникальное имя каталога, переданного в параметре.
Если каталога не существует, возвращается то же самое имя.
Если каталог существует к его имени добавляется порядковый номер в формате:
<имя target>-NNNN.<расширение target>
Возврат: уникальное имя каталога.
*/
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


/*
Дополняет строку символов s до длинны l символами c.
Возврат: дополненная строка.
*/
function padleft(s,l,c) {
	while(s.toString().length<l) s = c + s;
	return s;
}

function GetCharCodeHexString(sText) {
	var j, str1="";
	for(j=0;j<sText.length;++j) str1 += " " + sText.charCodeAt(j).toString(16);
	return str1.substr(1);
}

/*	Возвращает текст sText преобразованный из кодировки cp866 (DOS) в windows-1251. 
	Или наоборот - из 1251 в DOS - если флаг bInsideOut равен true.
	Взято: http://forum.script-coding.com/viewtopic.php?id=997
*/
 
function sDOS2Win(sText, bInsideOut) {
	var aCharsets = ["windows-1251", "cp866"];
	sText += "";
	bInsideOut = bInsideOut ? 1 : 0;
	with (new ActiveXObject("ADODB.Stream")) { //http://www.w3schools.com/ado/ado_ref_stream.asp
		type = 2; //Binary 1, Text 2 (default) 
		mode = 3; //Permissions have not been set 0,	Read-only 1,	Write-only 2,	Read-write 3,
		//Prevent other read 4,	Prevent other write 8,	Prevent other open 12,	Allow others all 16
		charset = aCharsets[bInsideOut];
		open();
		writeText(sText);
		position = 0;
		charset = aCharsets[1 - bInsideOut];
		return readText();
	}
}
