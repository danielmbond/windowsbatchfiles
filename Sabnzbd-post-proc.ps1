$ffmpeg = 'c:\ffmpeg\ffmpeg.exe' #download from http://ffmpeg.zeranoe.com/builds/
$plexScan = 'C:\PROGRA~2\Plex\PLEXME~1\PLEXME~2.EXE'
$downloadfolder = $env:USERPROFILE + '\Desktop\Downloads\'
$tvDest = "\\$networkComputer\Backup\TV\" #where to move tv shows to
$movieDest = "\\$networkComputer\Backup\Movies\" #where to move movies to
$dest = $tvDest
$networkComputer = "10.0.0.2" #ip address of networked computer to move files to

if($networkComputer -and !(Test-Connection -ComputerName $networkComputer -BufferSize 16 -Count 1 -Quiet))
{
    break;
}

Set-Location $downloadfolder
function DeleteNotMP4($inputpath)
{
    $inputpath = $inputpath.ToLower()
    if((Test-Path -Path $inputpath) -and ($inputpath.Contains("windows") -eq $false) -and ($inputpath.Contains("program") -eq $false) -and $inputpath -ne "c:\")
    {
        $exclude = @('*.mp4', '*.ps1', '*.cmd', '*.exe', '*.dll', '*.m4v')
        $files = Get-ChildItem -Path $inputpath -Exclude $exclude -Recurse| where {!$_.PSIsContainer}
        foreach($file in $files)
        {
            $mp4 = $file.DirectoryName + "\" + $file.BaseName + ".mp4" 
            if($file.Extension -eq ".mkv" -or $file.Extension -eq ".avi" -or $file.Extension -eq ".mpg")
            {
                if(Test-Path $mp4)
                {
                    Remove-Item $file
                }
            }
            if($file.Extension -ne ".mkv" -and $file.Extension -ne ".avi" -and $file.Extension -ne ".mpg")
            {
                Remove-Item $file
            }
        }
    }
}

function CheckForRunningFFMPEG()
{
    $ffmpeg = Get-Process -Name ffmpeg -ErrorAction SilentlyContinue
    if($ffmpeg -and $ffmpeg.CPU -lt 100)
    {
        $ffmpeg.Kill()
    }
}

function DelIfOtherExists($checkfile,$deletefile)
{
    if(Test-Path $checkfile)
    {
        Remove-Item $deletefile
    }
}

function ConvertToMP4($inputpath)
{
    if(Test-Path -Path $inputpath)
    {
        $files = Get-ChildItem -Path $inputpath -Include *.avi,*.mkv,*.mpg -Recurse
        foreach($file in $files)
        {
            $fullname = $file.FullName
            #write-host $fullname
            $mp4 = $file.DirectoryName + "\" + $file.BaseName + ".mp4"
            $args = '-c:v libx264'
            $loglevel = '-loglevel quiet'
            #write-host "c:\ffmpeg\ffmpeg.exe -i $fullname $args $mp4 -waitForExit" 
            #Invoke-Command -program "c:\ffmpeg\ffmpeg.exe" -waitForExit -argumentString "$fullname $args $mp4"
            Write-Host "Converting $fullname to $mp4"
            Invoke-Expression "$ffmpeg -i `"$fullname`" $args `"$mp4`" $loglevel" 
        }
    }
}

function TVRename($inputdirectory)
{
    if(Test-Path -Path $downloadfolder) 
    {
        $mp4s = Get-ChildItem $downloadfolder -Recurse -Include *.mp4,*.m4v
        foreach($mp4 in $mp4s)
        {
            $Matches = $null
            $basename = $mp4.BaseName 
            $basename
            $basename = $basename.Replace("."," ") 
            $basename = $basename.Replace("_"," ") 
            $basename = $basename -replace '[\[\]()\.]'
            $re1='((?:.*[sS][0-9][0-9][eE][0-9][0-9]*))'
            $basename -match $re1
            if($matches -and $matches[0])
            {
                $basename = $matches[0]
            }
            else
            {
                $basename = $mp4.BaseName
            }
            $basename = $basename -replace '[ ]+',' '
            $basename = $basename.Trim()
            $showName=($mp4.DirectoryName).Split("\")
            $showname = $showName[$showName.Count-1]
            if($showname -eq "Downloads")
            {
                $showname = ""
                $dest = $movieDest
                $fullname = $dest + $basename + ".mp4" 
            }
            else
            {
                $dest = $tvDest
                $showname = $showname + "\"
                $destShowPath = $dest + $showName
                if(!(Test-Path $destShowPath))
                {
                    New-Item $destShowPath -type directory
                }
                $fullname = $dest + $showName + $basename + ".mp4" 
            }

            if(!(Test-Path $fullname))
            {
                $mp4.MoveTo($fullname)
                #DelIfOtherExists $fullname $mp4.FullName
            }
            else
            {
                #DelIfOtherExists $fullname $mp4.FullName
            }
        } 
    }
}

CheckForRunningFFMPEG
DeleteNotMP4 $dest
DeleteNotMP4 $downloadfolder
ConvertToMP4 $dest
ConvertToMP4 $downloadfolder
TVRename $dest
TVRename $downloadfolder
Get-ChildItem $dest -Recurse -Include *.avi,*.mkv,*.mpg |%{Remove-Item $_}
Get-ChildItem $downloadfolder -Recurse -Include *.avi,*.mkv,*.mpg |%{Remove-Item $_}

Get-ChildItem $downloadfolder -recurse | Where {$_.PSIsContainer -and `
@(Get-ChildItem -LiteralPath $_.Fullname -Recurse | Where {!$_.PSIsContainer}).Length -eq 0} |
Remove-Item -Recurse
Get-ChildItem $dest -recurse | Where {$_.PSIsContainer -and `
@(Get-ChildItem -LiteralPath $_.Fullname -Recurse | Where {!$_.PSIsContainer}).Length -eq 0} |
Remove-Item -Recurse

Invoke-Expression "$plexScan --scan --refresh --force" | Out-Null
Write-Host "Complete"
