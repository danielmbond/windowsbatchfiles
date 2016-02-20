@echo off
rem Batch file to convert avi or mkv files to mp4 then move them to your iTunes import folder.
rem Need to download ffmpeg from http://ffmpeg.org and put it in your path or the download directory.
rem Change to where your video files go.
set downloads=%USERPROFILE%\Downloads
rem Default iTunes Automatically Add to iTunes folder.
set itunes=%USERPROFILE%\Music\iTunes\ITUNES~1\AUTOMA~1\
cd %downloads%
echo %downloads%
rem Delete crap files.
for /r "%downloads%" %%A in (*.srt *.txt *.idx *.sub *.srr *.par2 *.nzb *.jpg *.srs *.sfv *sample* *.nfo) do del "%%A"
echo $root = '%downloads%' > RenameVids.ps1
echo Set-Location $root >> RenameVids.ps1
echo if((Get-Location).Path -eq $root) >> RenameVids.ps1
echo { >> RenameVids.ps1
echo     $removeFromFilename = "bdrip", "ositv", "BDRip", "DEMAND", "HDTV", "x264", "FLEET", "TASTETV", "LOL", "KILLERS", ` >> RenameVids.ps1
echo     "2HD", "UAV", "OSiTV", "EVOLVE", "REPACK", "ALTEREGO", "AMIABLE", "EVO", "LEGION", "1080", "WEBDL", "DD5", "ettv", ` >> RenameVids.ps1
echo     "[", "]" >> RenameVids.ps1
echo     Get-ChildItem -Recurse -Include *.avi, *.mkv, *.mp4, *.txt ^| foreach($_){ >> RenameVids.ps1
echo         $basename = $_.BaseName >> RenameVids.ps1
echo         $basename = $basename.Replace("."," ") >> RenameVids.ps1
echo         $basename = $basename.Replace("-","") >> RenameVids.ps1
echo         foreach($word in $removeFromFilename) >> RenameVids.ps1
echo         { >> RenameVids.ps1
echo             $basename = $basename -replace $word >> RenameVids.ps1
echo             $basename = $basename.Replace("  "," ") >> RenameVids.ps1
echo         } >> RenameVids.ps1
echo         $basename = $basename.Trim() >> RenameVids.ps1
echo         $fullname = $root + "\" + $basename + $_.Extension >> RenameVids.ps1
echo         $_.MoveTo($fullname) >> RenameVids.ps1
echo         $fullname >> RenameVids.ps1
echo     } >> RenameVids.ps1
echo } >> RenameVids.ps1
echo while(Get-Process ffmpeg -ErrorAction SilentlyContinue) >> RenameVids.ps1
echo { >> RenameVids.ps1
echo 	Start-Sleep 300 >> RenameVids.ps1
echo } >> RenameVids.ps1
rem Remove a bunch of crap from the filename
PowerShell.exe -ExecutionPolicy Bypass -File %downloads%\RenameVids.ps1
rem If it's a mp4 move it to the itunes automatic download folder otherwise convert it to mp4 and move it. 
for /r "%downloads%" %%A IN (*.mp4) DO move "%%A" "%itunes%"
for /r "%downloads%" %%A IN (*.mkv) DO ffmpeg.exe -i "%%A" -strict experimental -map 0:0? -map 0:1? -map 0:2? -map 0:3? -c:v copy -c:a aac -b:a 384k -c:s copy "%%A.mp4"
for /r "%downloads%" %%A IN (*.mp4) DO move "%%A" "%itunes%"
for /r "%downloads%" %%A IN (*.avi) DO ffmpeg.exe -i "%%A" -strict experimental -map 0:0? -map 0:1? -map 0:2? -map 0:3? -c:v copy -c:a aac -b:a 384k -c:s copy "%%A.mp4"
for /r "%downloads%" %%A IN (*.mp4) DO move "%%A" "%itunes%"
rem Remove empty directories.
for /r "%downloads%" %%A IN (.) DO rd "%%A"
for /r "%downloads%" %%A IN (.) DO rd "%%A"
for /r "%downloads%" %%A in (*.mkv *.avi) do del "%%A"