@ECHO OFF
SET FFMPEG="C:\ffmpeg\ffmpeg.exe"
SET itunes=%USERPROFILE%\Music\iTunes\ITUNES~1\HOMEVI~1\TV\
SET downloads=%USERPROFILE%\Desktop\Downloads
SET SCANNER="C:\Program Files (x86)\Plex\Plex Media Server\Plex Media Scanner.exe"
SET SABNZBD="C:\PROGRA~2\SABnzbd\SABnzbd.exe"
SET APIKEY=YOUR_API_KEY_GOES_HERE

rem echo stopping sabnzbd
rem curl "https://127.0.0.1:9090/sabnzbd/api?mode=shutdown&apikey=%APIKEY%"

REM Kill ffmpeg if it's not doing anything.
set "process_name=ffmpeg.exe"
::remove .exe suffix if there is
set pn=%process_name:.exe=%

setlocal enableDelayedExpansion

set c=0
:: getting three snapshots of CPU usage of the given process
for /f skip^=2^ tokens^=3^ delims^=^" %%p in ('typeperf "\Process(%pn%)\%% Processor Time"  -sc 3') do (
    set /a counter=counter+1
    for /f "tokens=1,2 delims=." %%a in ("%%p") do set  "process_snapshot_!counter!=%%a%%b"

)

:: remove rem to see the cpu usage from the three snapshots
set process_snapshot_

:: if all three snapshots are less than 0000010 process will be killed
if 1%process_snapshot_1% LSS 10000010 if 1%process_snapshot_2% LSS 10000010 if 1%process_snapshot_3% LSS 10000010 (
     tskill %pn%
)

ECHO Looking in "%itunes%" to convert .avi and .mkv files...
for /r "%itunes%" %%A IN (*.mkv) DO %FFMPEG% -i "%%A" -c:v libx264 "%%~pA\%%~nA.mp4"
for /r "%itunes%" %%A IN (*.avi) DO %FFMPEG% -i "%%A" -c:v libx264 "%%~pA\%%~nA.mp4"
ECHO delete everything in %itunes% that's not an mp4
for /R %itunes% %%G IN (*) do if not %%~xG==.mp4 del "%%G"
ECHO delete mkvs and avis in %downloads%
cd %downloads%
for /r "%downloads%" %%A in (*.mkv *.avi) do del "%%A"
echo $root = '%downloads' > RenameVids.ps1
echo $itunes = '%itunes%' >> RenameVids.ps1
echo Set-Location $root  >> RenameVids.ps1
echo if((Get-Location).Path -eq $root)  >> RenameVids.ps1
echo { >> RenameVids.ps1
echo     $mp4s = Get-ChildItem -Recurse -Include *.mp4 >> RenameVids.ps1
echo     >> RenameVids.ps1
echo     foreach($mp4 in $mp4s) >> RenameVids.ps1
echo     {  >> RenameVids.ps1
echo      >> RenameVids.ps1
echo         $basename = $mp4.BaseName  >> RenameVids.ps1
echo         $basename >> RenameVids.ps1
echo         $basename = $basename.Replace("."," ")  >> RenameVids.ps1
echo         $basename = $basename.Replace("_"," ")  >> RenameVids.ps1
echo         $basename = $basename -replace '[\[\]()\.]' >> RenameVids.ps1
echo         $re1='((?:.*[sS][0-9][0-9][eE][0-9][0-9]*))' >> RenameVids.ps1 #look for the S00E00 patern and delete everything after it
echo         $basename -match $re1 >> RenameVids.ps1
echo         if($matches[0]) >> RenameVids.ps1
echo         { >> RenameVids.ps1
echo             $basename = $matches[0] >> RenameVids.ps1
echo         } >> RenameVids.ps1
echo         while($basename.contains("  ")) >> RenameVids.ps1
echo         { >> RenameVids.ps1
echo             $basename.replace("  "," ") >> RenameVids.ps1
echo         } >> RenameVids.ps1
echo         $basename = $basename.Trim() >> RenameVids.ps1
echo         $showName=($mp4.DirectoryName).Split("\") >> RenameVids.ps1
echo         $showname = $showName[$showName.Count-1] >> RenameVids.ps1
echo         $itunesShowPath = $itunes + $showName + "\" >> RenameVids.ps1
echo         if(!(Test-Path $itunesShowPath)) >> RenameVids.ps1
echo         { >> RenameVids.ps1
echo             New-Item $itunesShowPath -type directory >> RenameVids.ps1
echo         } >> RenameVids.ps1
echo         $fullname = $itunes + $showName + "\" + $basename + $mp4.Extension  >> RenameVids.ps1
echo         $mp4.MoveTo($fullname)  >> RenameVids.ps1
echo         $fullname  >> RenameVids.ps1
echo     }  >> RenameVids.ps1
echo } >> RenameVids.ps1
PowerShell.exe -ExecutionPolicy Bypass -File %downloads%\RenameVids.ps1
rem Remove empty directories.
for /r "%downloads%" %%A IN (.) DO rd "%%A"
for /r "%itunes%" %%A IN (.) DO rd "%%A"
rem echo starting sabnzbd
rem start %SABNZBD%
ECHO Refreshing PLEX
%SCANNER% --scan --refresh --force
ECHO Post processing complete.
