
REM ####################################################
REM Script to apply PSOFT CPU 2019 July
REM ####################################################
REM NOTE Expected Repository Structure
REM ..\CPU-yyyy-mmm\Software\java\*.zip(s)
REM ..\CPU-yyyy-mmm\Software\opatch\*.zip(s)
REM ..\CPU-yyyy-mmm\Software\WLS\*.zip(s)
REM ..\CPU-yyyy-mmm\Backups\*empty*
REM ..\CPU-yyyy-mmm\Logs\*empty*

REM ####################################################
REM Initial Setup
REM ####################################################

set CPUFOLDER=CPU-2019-July
set CPUDIR=D:\psoft\patches\%CPUFOLDER%
set CPUREPOSITORY=\\am1hrap905\CedarTeam\30-Technical\95-Critical-Patch-Updates-CPUs\%CPUFOLDER%

set ORACLE_HOME=D:\psoft\oracle\weblogic
set PS_HOME=D:\psoft\ps_home\pt85610
set JDKDIR=D:\psoft\java\jdk

REM Pre Pend JDK and OPatch to Path
set PATH=%ORACLE_HOME%\OPatch;%PATH%
set PATH=%JDKDIR%\bin;%PATH%

REM ####################################################
REM List Current Software Versions
REM ####################################################

REM WebLogic
opatch version
opatch lspatches
REM opatch lsinventory -jre %JDKDIR%

REM Java
java -version
%JDKDIR%\bin\java -version

REM ####################################################
REM Copy down software from share (zip files only)
REM ####################################################
ROBOCOPY /L /S /E %CPUREPOSITORY% %CPUDIR% *.zip

REM ####################################################
REM Stop PIA Services
REM ####################################################
powershell Get-Service *PIA
powershell Stop-Service *PIA -Force
powershell Get-Service *PIA

REM ####################################################
REM Patch JAVA
REM ####################################################

REM Change To Patch Directory and Unzip Patch
cd /d %CPUDIR%\software\java
%JDKDIR%\bin\jar.exe xvf p18143322_1800_MSWIN-x86-64.zip

REM Archive Current Java
set LOGFILE=%CPUDIR%\logs\java_robocopy.log
REM robocopy /l /mir                 %JDKDIR% %CPUDIR%\backups\java
robocopy    /mir /log+:%LOGFILE% %JDKDIR% %CPUDIR%\backups\java
REM compact /c /s %CPUDIR%\backups\java\*
ren %JDKDIR% jdk-delete-me

REM Install JDK ( ... wait 180 seconds for install to complete ... )
jdk-8u221-windows-x64.exe INSTALLDIR=%JDKDIR% /s /L %CPUDIR%\logs\jdk-8u221-windows-x64_install.log
timeout 180

REM Re-Check Version(s) (Should now return new version)
%JDKDIR%\bin\java -version
%PS_HOME%\jre\bin\java -version

REM Remove Old Java
del %JDKDIR%-delete-me

REM ####################################################
REM Backup WEBLOGIC
REM ####################################################
set LOGFILE=%CPUDIR%\logs\weblogic_robocopy.log
REM robocopy /L /mir                 %ORACLE_HOME% %CPUDIR%\backups\weblogic
robocopy    /mir /log+:%LOGFILE% %ORACLE_HOME% %CPUDIR%\backups\weblogic
REM compact /c /s %CPUDIR%\backups\weblogic\*

REM ####################################################
REM Patch OPATCH
REM ####################################################

REM Patch(1) OPATCH p28186730_139400_Generic.zip / 6880880
REM Unzip & Apply Patch
cd /d %CPUDIR%\software\OPatch
%JDKDIR%\bin\jar.exe xvf p28186730_139400_Generic.zip
cd 6880880
java -jar opatch_generic.jar -J-Doracle.installer.oh_admin_acl=true -silent oracle_home=%ORACLE_HOME%

REM Patch(2) OPATCH p29909359_139400_Generic / 29909359
REM Unzip & Apply Patch
cd /d %CPUDIR%\software\OPatch
%JDKDIR%\bin\jar.exe xvf p29909359_139400_Generic.zip
cd 29909359
opatch apply -jre %JDKDIR% -oop
REM opatch rollback -id 29909359

REM ####################################################
REM Patch WEBLOGIC
REM ####################################################

REM Unzip & Apply Patch
cd /d %CPUDIR%\software\WLS
%JDKDIR%\bin\jar.exe xvf p29814665_122130_Generic.zip
cd 29814665
opatch apply -jre %JDKDIR% -oop
REM opatch rollback -id 29814665

REM ####################################################
REM List Final Software Versions
REM ####################################################

REM WebLogic
opatch version
opatch lspatches
REM opatch lsinventory -jre %JDKDIR%

REM Java
java -version
%JDKDIR%\bin\java -version

REM ####################################################
REM Start PIA Services
REM ####################################################
powershell Get-Service *PIA
powershell Start-Service *PIA
powershell Get-Service *PIA

REM ####################################################
REM Cleanup
REM ####################################################
compact /c /s %CPUDIR%\backups\*
