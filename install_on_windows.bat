@echo off
cd %TMP%

rem Download the Pike installer and Succotash's client
rem http://superuser.com/a/760010
powershell -command "& { (New-Object Net.WebClient).DownloadFile('http://pike.lysator.liu.se/pub/pike/latest-stable/Pike-v8.0.388-win32-oldlibs.msi', 'pike.msi') }"
start /wait pike.msi
mkdir c:\Succotash
cd c:\Succotash
powershell -command "& { (New-Object Net.WebClient).DownloadFile('http://rosuav.github.io/miniature-succotash/succotash.pike', 'succotash.pike') }"

rem Create a shortcut. In theory, WindowStyle=7 should give a minimized window.
rem TODO: Find the desktop directory even if it isn't obvious.
rem TODO: Put a shortcut also into the Start menu? Does that require elevation?
rem (Shouldn't - not for per-user start menu at least.) Where should it be put?
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%userprofile%\Desktop\Succotash.lnk');$s.TargetPath='c:\Succotash\succotash.pike';$s.WorkingDirectory='c:\Succotash';$s.WindowStyle=7;$s.Save()"
