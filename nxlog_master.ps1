﻿# FileName: nxlog_master.ps1
#
# Last Modified 5/10/2016
# Created by: Justin Henderson
# Email: jhenderson@tekrefresh.com
#

# This script is used to install, upgrade, and maintain nxlog config files

# Need to modify module and binary download functions to do version checks

# Define the parameters of this script.
Param(
  [string]$Version = "", 
  [string]$MSILocation = "http://someserver/nxlog/nxlog-2.9.1427.msi",
  [string]$script:webFileLocation = "http://someserver/nxlog",
  [string]$script:logstashHost = "someserver",
  [string]$script:scriptPath = "C:\scripts\nxlog"
)

# Set variables - DO NOT CHANGE
$script:binPath = "$script:scriptPath\bin"
$script:modulePath = "$script:scriptPath\modules"

# Store whether the system is 32-bit or 64-bit (AMD64)
$script:architecture = $ENV:PROCESSOR_ARCHITECTURE

# Test if $script:scriptPath exists and if not create it
if(!(Test-Path -Path $script:scriptPath)){
    New-Item -Path $script:scriptPath -ItemType directory -Force
}

# Test if $script:scriptPath\bin exists and if not create it
if(!(Test-Path -Path "$script:binPath")){
    New-Item -Path "$script:binPath" -ItemType directory    
}

# Test if $script:scriptPath\modules exists and if not create it
if(!(Test-Path -Path "$script:modulePath")){
    New-Item -Path "$script:modulePath" -ItemType directory    
}

function binaryDownload($filePath){
    if($script:architecture -eq "AMD64"){
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile("$script:webFileLocation/binaries/sha1deep64.exe","$script:binPath\sha1deep64.exe")
    } else {
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile("$script:webFileLocation/binaries/sha1deep.exe","$script:binPath\sha1deep.exe")
    }
    $content = Get-Content -Path $filePath
    $licenseIssueStart = Select-String $filePath -pattern "license_issue_start" | Select -property LineNumber
    $licenseIssueStart = $licenseIssueStart.LineNumber
    $licenseIssueEnd = Select-String $filePath -pattern "license_issue_end" | Select -property LineNumber
    $licenseIssueEnd = $licenseIssueEnd.LineNumber
    if(($licenseIssueEnd -1) -gt $licenseIssueStart){
        (Get-Content -Path $filePath)[$licenseIssueStart .. ($licenseIssueEnd - 2)] | ForEach-Object {
            $array = $_.Split(',')
            $exe = $array[0]
            $hash = $array[1]
            if(!(Test-Path -Path "$script:binPath\$exe")){
                Write-Host "Attempting to download $exe"
                $WebClient = New-Object System.Net.WebClient
                $WebClient.DownloadFile("$script:webFileLocation/binaries/$exe","$script:binPath\$exe")
            }
            if($script:architecture -eq "AMD64"){
                    $binaryHash = & "$script:binPath\sha1deep64.exe" "$script:binPath\$exe"
            } else {
                $binaryHash = & "$script:binPath\sha1deep.exe" "$script:binPath\$exe"
            }
            $binaryHash = $binaryHash.substring(0,$binaryHash.indexof(" "))
            if($binaryHash -ne $hash){
                Write-Host "Binary updated. Downloading $exe"
                $WebClient = New-Object System.Net.WebClient
                $WebClient.DownloadFile("$script:webFileLocation/binaries/$exe","$script:binPath\$exe")
            }
        }
    }
    if($script:architecture -ne "AMD64"){
        $32Start = Select-String $filePath -pattern "x86_start" | Select -Property LineNumber
        $32Start = $32Start.LineNumber
        $32End = Select-String $filePath -pattern "x86_end" | Select -Property LineNumber
        $32End = $32End.LineNumber
        if(($32End -1) -gt $32Start){
            (Get-Content -Path $filePath)[$32Start .. ($32End - 2)] | ForEach-Object {
                $array = $_.Split(',')
                $exe = $array[0]
                $hash = $array[1]
                if(!(Test-Path -Path "$script:binPath\$exe")){
                    Write-Host "Attempting to download $exe"
                    $WebClient = New-Object System.Net.WebClient
                    $WebClient.DownloadFile("$script:webFileLocation/binaries/$exe","$script:binPath\$exe")
                }
                if($script:architecture -eq "AMD64"){
                    $binaryHash = & "$script:binPath\sha1deep64.exe" "$script:binPath\$exe"
                } else {
                    $binaryHash = & "$script:binPath\sha1deep.exe" "$script:binPath\$exe"
                }
                $binaryHash = $binaryHash.substring(0,$binaryHash.indexof(" "))
                if($binaryHash -ne $hash){
                    Write-Host "Binary updated. Downloading $exe"
                    $WebClient = New-Object System.Net.WebClient
                    $WebClient.DownloadFile("$script:webFileLocation/binaries/$exe","$script:binPath\$exe")
                }
            }
        }
    } else {
        $64Start = Select-String $filePath -pattern "x64_start" | Select -Property LineNumber
        $64Start = $64Start.LineNumber
        $64End = Select-String $filePath -pattern "x64_end" | Select -Property LineNumber
        $64End = $64End.LineNumber
        if(($64End -1) -gt $64Start){
            (Get-Content -Path $filePath)[$64Start .. ($64End - 2)] | ForEach-Object {
                $array = $_.Split(',')
                $exe = $array[0]
                $hash = $array[1]
                if(!(Test-Path -Path "$script:binPath\$exe")){
                    Write-Host "Attempting to download $exe"
                    $WebClient = New-Object System.Net.WebClient
                    $WebClient.DownloadFile("$script:webFileLocation/binaries/$exe","$script:binPath\$exe")
                }
                if($script:architecture -eq "AMD64"){
                    $binaryHash = & "$script:binPath\sha1deep64.exe" "$script:binPath\$exe"
                } else {
                    $binaryHash = & "$script:binPath\sha1deep.exe" "$script:binPath\$exe"
                }
                $binaryHash = $binaryHash.substring(0,$binaryHash.indexof(" "))
                if($binaryHash -ne $hash){
                    Write-Host "Binary updated. Downloading $exe"
                    $WebClient = New-Object System.Net.WebClient
                    $WebClient.DownloadFile("$script:webFileLocation/binaries/$exe","$script:binPath\$exe")
                }
            }
        }
    }
}

function moduleDownload($filePath){
    $content = Get-Content -Path $filePath
    Get-Content -Path $filePath | ForEach-Object {
        $array = $_.Split(',')
        $module = $array[0]
        $hash = $array[1]
        if(!(Test-Path -Path "$script:modulePath\$module")){
            Write-Host "Attempting to download $module"
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile("$script:webFileLocation/modules/$module","$script:modulePath\$module")
        }
        if($script:architecture -eq "AMD64"){
            $moduleHash = & "$script:binPath\sha1deep64.exe" "$script:modulePath\$module"
        } else {
            $moduleHash = & "$script:binPath\sha1deep.exe" "$script:modulePath\$module"
        }
        $moduleHash = $moduleHash.substring(0,$moduleHash.indexof(" "))
        if($moduleHash -ne $hash){
            Write-Host "module updated. Downloading $module"
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile("$script:webFileLocation/modules/$module","$script:modulePath\$module")
        }
    }
}

# Grab list of binaries
Remove-Item -Path "$script:binPath\bin.txt" -Force -ErrorAction SilentlyContinue
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("$script:webFileLocation/binaries/bin.txt","$script:binPath\bin.txt")
binaryDownload("$script:binPath\bin.txt")

# Grab list of modules
Remove-Item -Path "$script:modulePath\module.txt" -Force -ErrorAction SilentlyContinue
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("$script:webFileLocation/modules/module.txt","$script:modulePath\module.txt")
moduleDownload("$script:modulePath\module.txt")

# Check if NXLog is installed and the current version
if($script:architecture -eq "AMD64"){
    if(((Get-ItemProperty HKLM:\Software\WoW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -contains "NXLog" } | Select-Object -expand DisplayVersion) -ne $Version) -or (!(Test-Path -Path "C:\Program Files (x86)\nxlog\nxlog.exe"))){
       # Run installer to perform install or upgrade
       if(!(Test-Path -Path "$script:scriptPath\nxlog.msi")){
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile($MSILocation,"$script:scriptPath\nxlog.msi")
        }
       & "msiexec.exe" @('/i', "$script:scriptPath\nxlog.msi", '/qn')
       While((Get-Service -Name nxlog -ErrorAction SilentlyContinue).Status -ne "Running"){
            Write-Host "Waiting on nxlog to finish installing"
            Sleep -Seconds 5
            Start-Service nxlog -ErrorAction SilentlyContinue
       }
       Write-Host "NXlog is installed"
       Sleep -Seconds 5
    }
} else {
    if(((Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -contains "NXLog" } | Select-Object -expand DisplayVersion) -ne $Version) -or (!(Test-Path -Path "C:\Program Files\nxlog\nxlog.exe"))){
        # Run installer to perform install or upgrade
        if(!(Test-Path -Path "$script:scriptPath\nxlog.msi")){
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile($MSILocation,"$script:scriptPath\nxlog.msi")
        }
        & "msiexec.exe" @('/i', "$script:scriptPath\nxlog.msi", '/qn')
        While((Get-Service -Name nxlog -ErrorAction SilentlyContinue).Status -ne "Running"){
            Write-Host "Waiting on nxlog to finish installing"
            Sleep -Seconds 5
            Start-Service nxlog -ErrorAction SilentlyContinue
       }
       Write-Host "NXlog is installed"
       Sleep -Seconds 5
    }
}

# Store the base configuration in $script:conf variable which will be written out to a temporary file for hash check.

$script:conf = "

Panic Soft
#NoFreeOnExit TRUE

"

if($script:architecture -eq "x86"){
    $nxlogpath = "C:\Program Files\nxlog"
    $script:conf += "define ROOT C:\Program Files\nxlog"
} else {
    $nxlogpath = "C:\Program Files (x86)\nxlog"
    $script:conf += "define ROOT C:\Program Files (x86)\nxlog"
}

$script:conf += "

define CERTDIR %ROOT%\cert
define CONFDIR %ROOT%\conf
define LOGDIR %ROOT%\data

LogLevel INFO
Logfile %LOGDIR%\nxlog.log

SuppressRepeatingLogs TRUE

moduledir %ROOT%\modules
CacheDir %ROOT%\data
Pidfile %ROOT%\data\nxlog.pid
SpoolDir %ROOT%\data

<Extension _syslog>
    module      xm_syslog
</Extension>

<Extension _charconv>
    module      xm_charconv
    AutodetectCharsets iso8859-2, utf-8, utf-16, utf-32
</Extension>

<Extension _exec>
    module      xm_exec
</Extension>

<Extension json>
    module xm_json
</Extension>

<Extension _fileop>
    module      xm_fileop
</Extension>

#include %CONFDIR%\log4ensics.conf

"

# Launch modules - If parameter specificied load modules via parameter otherwise default
# to the modules folder in the current working directory
$modules = Get-ChildItem -Path $script:modulePath -Filter *.ps1

if($modules){
    foreach($module in $modules){
        . $module.FullName
    }
}

# Create temporary configuration file, hash this file, and compare to current file if any
# If match... exit.  If there is not a match, overwrite

# Create temp configuration file
$script:conf | Out-File -Force -Encoding ASCII "C:\Windows\Temp\nxlog.conf"

if($architecture -eq "AMD64"){
    $temphash = & "$script:binPath\sha1deep64.exe" "C:\Windows\Temp\nxlog.conf"
} else {
    $temphash = & "$script:binPath\sha1deep.exe" "C:\Windows\Temp\nxlog.conf"
}
$temphash = $temphash.substring(0,$temphash.indexof(" "))

if($script:architecture -eq "AMD64"){
    $prodhash = & "$script:binPath\sha1deep64.exe" "$nxlogpath\conf\nxlog.conf"
} else {
    $prodhash = & "$script:binPath\sha1deep.exe" "$nxlogpath\conf\nxlog.conf"
}

$prodhash = $prodhash.substring(0,$prodhash.indexof(" "))

# Save NXLog config
if($prodhash -ne $temphash){
    Write-Host "TempHash is: $temphash" -ForegroundColor Red
    Write-Host "ProdHash is: $prodhash" -ForegroundColor Green
    $script:conf | Out-File -force -Encoding ASCII "$nxlogpath\conf\nxlog.conf"
    Write-Host "File overwritten" -ForegroundColor Blue
    # Restart services
    Stop-Service -Force nxlog
    Remove-Item -Force "C:\Program Files (x86)\nxlog\data\nxlog.log" -ErrorAction SilentlyContinue
    Remove-Item -Force "C:\Program Files\nxlog\data\nxlog.log" -ErrorAction SilentlyContinue
    Start-Service nxlog
} else {
    Stop-Service -Force nxlog
    Start-Service nxlog
}

if((Get-Service -Name nxlog).Status -eq "Running"){
    Write-Host "NXLog is running smoothly. Ending script..." -ForegroundColor Green
} else {
    Write-Host "NXLog is not running.  Something maybe wrong" -ForegroundColor Red
}
