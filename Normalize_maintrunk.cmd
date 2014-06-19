@echo off
set NormalizeLogDir=F:\dobuild\logs
set OutputEmailFile=F:\dobuild\logs\Normalize.email.txt
set NormalizeLogFile=%NormalizeLogDir%\BuildAll.build.log
set TUSPackageLogFile=%NormalizeLogDir%\TUSPackage.build.log

del /Q F:\bdna\BMS\Solutions2\Solutions\setup\NSIS\setup.exe
del /Q %OutputEmailFile%
del /Q %NormalizeLogFile%
del /Q %TUSPackageLogFile%

echo [%date% %time%] Script started on %COMPUTERNAME%. > %OutputEmailFile%
echo [%date% %time%] Checkout from CVS (bdna/BMS/Solutions2). >> %OutputEmailFile%


f:
cd \
rmdir /s /q f:\bdna
rmdir /s /q f:\release
cvs co bdna/BMS/Solutions2
REM cvs co "release/normalize4.00/Console_Help/TechNorm40_Console_Help/!SSL!/WebHelp/"
cvs co "release/normalize4.2/BDNANorm42_Console_Help/!SSL!/WebHelp/"

SETLOCAL ENABLEDELAYEDEXPANSION

echo [%date% %time%] Completed CVS checkout. >> %OutputEmailFile%

type F:\bdna\BMS\Solutions2\Solutions\Setup\NSIS\Resources\install.config >> %OutputEmailFile%

echo [%date% %time%] Running F:\bdna\BMS\Solutions2\Solutions\NightlyBuild\BuildAll.build. >> %OutputEmailFile%
cd F:\bdna\BMS\Solutions2\Solutions\NightlyBuild
nant -buildfile:BuildAll.build > %NormalizeLogFile%
echo [%date% %time%] Completed BuildAll.build. >> %OutputEmailFile%

echo [%date% %time%] Running F:\bdna\BMS\Solutions2\Solutions\NightlyBuild\TUSPackage.build. >> %OutputEmailFile%
cd F:\bdna\BMS\Solutions2\Solutions\NightlyBuild
nant -buildfile:TUSPackage.build > %TUSPackageLogFile%
echo [%date% %time%] Completed TUSPackage.build. >> %OutputEmailFile%


copy versionbuf.number version.number /Y

for /f %%z in (F:\bdna\BMS\Solutions2\Solutions\NightlyBuild\version.number) do (
  set version=%%z
)



for /f "tokens=1,2,3,4 delims=." %%a in ("%version%") do (
  set version_major=%%a
  set version_minor=%%b
  set version_patch=%%c
  set version_build=%%d
)


for /f "tokens=1,2" %%u in ('date /t') do set d=%%v 
set year=%d:~6,4%
set month=%d:~0,2%
set day=%d:~3,2% 
set year=%year: =%
set month=%month: =%
set day=%day: =%


for /f "tokens=1,2 delims=/:. " %%i in ("%time: =0%") do set "m=%%i%%j"
set hour=%m:~0,2%
set min=%m:~2,2% 
set hour=%hour: =%
set min=%min: =%

cvs commit -m "updated Normalize build number to %version_build%" version.number

echo DEBUG: %date% %time% >> %OutputEmailFile%
echo DEBUG: Date: %year%-%month%-%day% >> %OutputEmailFile%
echo DEBUG: Time: %hour%:%min% >> %OutputEmailFile%

echo DEBUG: version_major=%version_major% >> %OutputEmailFile%
echo DEBUG: version_minor=%version_minor% >> %OutputEmailFile%
echo DEBUG: version_patch=%version_patch% >> %OutputEmailFile%
echo DEBUG: version_build=%version_build% >> %OutputEmailFile%

set build_dir=%year%_%month%_%day%_%hour%_%min%_%version_build%

echo end function executed >> %OutputEmailFile%

net use \\nas2\shared /USER:bdnacorp\buildqa n1md@345
mkdir \\nas2\shared\product\nightly-builds\normalize\%version_major%.%version_minor%.%version_patch%\%build_dir%
copy /y F:\bdna\BMS\Solutions2\Solutions\setup\NSIS\Normalize*.exe \\nas2\shared\product\nightly-builds\normalize\%version_major%.%version_minor%.%version_patch%\%build_dir% >> %OutputEmailFile%

mkdir \\nas2\shared\product\nightly-builds\normalize\%version_major%.%version_minor%.%version_patch%\%build_dir%\TUSPackage
xcopy /s/e/v/y F:\bdna\BMS\Solutions2\Solutions\Release\build_%year%\%month%\%day%\TUSPackage \\nas2\shared\product\nightly-builds\normalize\%version_major%.%version_minor%.%version_patch%\%build_dir%\TUSPackage >> %OutputEmailFile%

mkdir \\nas2\shared\product\nightly-builds\normalize\%version_major%.%version_minor%.%version_patch%\%build_dir%\TUS
xcopy /s/e/v/y F:\bdna\BMS\Solutions2\Solutions\Release\build_%year%\%month%\%day%\TUS \\nas2\shared\product\nightly-builds\normalize\%version_major%.%version_minor%.%version_patch%\%build_dir%\TUS >> %OutputEmailFile%

mkdir \\nas2\shared\product\nightly-builds\normalize\%version_major%.%version_minor%.%version_patch%\%build_dir%\Extractor
xcopy /s/e/v/y F:\bdna\BMS\Solutions2\Solutions\Release\build_%year%\%month%\%day%\Extractor \\nas2\shared\product\nightly-builds\normalize\%version_major%.%version_minor%.%version_patch%\%build_dir%\Extractor >> %OutputEmailFile%

copy /y %NormalizeLogFile% \\nas2\shared\product\nightly-builds\normalize\%version_major%.%version_minor%.%version_patch%\%build_dir%
copy /y %TUSPackageLogFile% \\nas2\shared\product\nightly-builds\normalize\%version_major%.%version_minor%.%version_patch%\%build_dir%

echo Latest nightly build directory: \\nas2\shared\product\nightly-builds\normalize\%version_major%.%version_minor%.%version_patch%\%build_dir% >> %OutputEmailFile%
echo [%date% %time%] Script completed. >> %OutputEmailFile%


findstr /C:"BUILD FAILED" %NormalizeLogFile% 2>&1 > NUL
IF %ERRORLEVEL% EQU 0 goto end_failed

set Result="Succeeded" 
f:\dobuild\tools\blat.exe -server mail.bdnacorp.com -f "buildstatus@bdna.com" -to "build-normalize@bdna.com" -subject "Normalize %version_major%.%version_minor%.%version_patch% Nightly Build %version_build% - %Result%" -bodyF %OutputEmailFile%
goto end

:end_failed
set Result="Failed" 
f:\dobuild\tools\blat.exe -server mail.bdnacorp.com -f "buildstatus@bdna.com" -to "build-normalize@bdna.com" -subject "Normalize %version_major%.%version_minor%.%version_patch% Nightly Build %version_build% - %Result%" -bodyF %OutputEmailFile%

:end
endlocal
