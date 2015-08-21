var winhwnd = WScript.Arguments(0);
var objShell = new ActiveXObject("shell.application");
var ssfWINDOWS = 36;
var objFolder;
objFolder = objShell.BrowseForFolder(winhwnd, "Выберите каталог сохранения изображений.  Нажмите 'Отмена' для замены оригинальных изображений на оптимизированные.", 0+1+16+64+16384);
if (objFolder != null)
{
	WScript.echo(objFolder.self.Path);
}
