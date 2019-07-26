
REM ####################################################
REM Set Common Variables
REM ####################################################
set ORACLE_HOME=D:\psoft\oracle\weblogic
set PS_HOME=D:\psoft\ps_home\pt85610
set JKDDIR=D:\psoft\java\jdk
set PATCHDIR=D:\psoft\patches\CPU-2019-July\software
set PATH=%ORACLE_HOME%\OPatch;%PATH%
set PATH=%JKDDIR%\bin;%PATH%

REM ####################################################
REM List Current Software Versions
REM ####################################################
REM WebLogic
REM set ORACLE_HOME=D:\psoft\oracle\weblogic
REM set PATH=%ORACLE_HOME%\OPatch;%PATH%
opatch version
opatch lspatches
REM opatch lsinventory -jre %JDKDIR%
REM Java
%JKDDIR%\bin\java -version
%PS_HOME%\jre\bin\java -version


REM ####################################################
REM Backup JAVA
REM ####################################################
# Backup Directories
${Env:CPU}           = 'CPU-2019-July'
${Env:CPU_BKP_Dir}   = "D:/psoft/patches/${CPU}/backups"
cmd /c robocopy /mir 

rename-item -path ${Env:JRE} -NewName ${Env:JRE}-${Env:CPU_BKP_SFX}


REM ####################################################
REM Backup WEBLOGIC
REM ####################################################
$SRC_Dir  = 'D:\psoft\oracle\weblogic'
$TGT_Dir  = "${CPU_BKP_Dir}/weblogic"
$LOG_File = "${CPU_LOG_Dir}/weblogic_robocopy.log"

robocopy /mir /log+:$LOG_File $SRC_Dir $TGT_Dir

REM ####################################################
REM Patch JAVA
REM ####################################################
REM Change To Patch Directory and Unzip Patch
REM set PATCHDIR=D:\psoft\patches\CPU-2019-July\software
cd /d %PATCHDIR%\JDK
REM set JDKDIR=D:\psoft\java\jdk
%JDKDir%\bin\jar.exe xvf p18143322_1800_MSWIN-x86-64.zip

REM Install JDK (and wait 180 seconds for install to complete)
jdk-8u221-windows-x64.exe INSTALLDIR=%JDKDir% /s /L %PATCHDIR%\logs\jdk-8u221-windows-x64_install.log
timeout 180

REM Check Versions (Should return build 1.8.0_221-b27)
%JDKDIR%\bin\java -version

REM ####################################################
REM Patch OPATCH p28186730_139400_Generic.zip
REM ####################################################
REM set ORACLE_HOME=D:\psoft\oracle\weblogic
REM set PATH=%ORACLE_HOME%\OPatch;%PATH%
REM set PATCHDIR=D:\psoft\patches\CPU-2019-July\software
REM set JDKDIR=D:\psoft\java\jdk
cd /d %PATCHDIR%\OPatch
%JDKDir%\bin\jar.exe xvf p28186730_139400_Generic.zip
cd 6880880
java -jar opatch_generic.jar -J-Doracle.installer.oh_admin_acl=true -silent oracle_home=%ORACLE_HOME%

REM ####################################################
REM Patch OPATCH p29909359_139400_Generic
REM ####################################################
REM set ORACLE_HOME=D:\psoft\oracle\weblogic
REM set PATH=%ORACLE_HOME%\OPatch;%PATH%
REM set PATCHDIR=D:\psoft\patches\CPU-2019-July\software
REM set JDKDIR=D:\psoft\java\jdk
cd /d %PATCHDIR%\OPatch
%JDKDir%\bin\jar.exe xvf p29909359_139400_Generic.zip
cd 29909359
opatch apply -jre %JDKDIR% -oop
REM opatch rollback -id 29909359

REM ####################################################
REM Patch WEBLOGIC
REM ####################################################
REM Apply New PSU
cd /d %PATCHDIR%\WLS
%JDKDir%\bin\jar.exe xvf p29814665_122130_Generic.zip
cd %PATCHDIR%\WLS\29814665
opatch apply -jre %JDKDIR% -oop
REM opatch rollback -id 29814665
