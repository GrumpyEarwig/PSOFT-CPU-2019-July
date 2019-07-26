
# ####################################################
# Preparatory Steps
# ####################################################

# Set some variables

$CPU = 'CPU-2019-July'
${Env:CPU_Patch_Dir} = "//am1hrap905/CedarTeam/30-Technical/95-Critical-Patch-Updates-CPUs/${Env:CPU}"
${Env:CPU_BKP_Dir}   = "D:/psoft/patches/${Env:CPU}/backups"
${Env:CPU_BKP_SFX}   = "BKP-B4-${Env:CPU}"

# Check Services Are Running
get-service '*-PIA' | format-table -AutoSize
get-service '*-PIA' | Stop-Service -force
get-service '*-PIA' | format-table -AutoSize

# List Software Versions
${Env:ORACLE_HOME} = 'D:\psoft\oracle\weblogic'
${Env:PATH}        = "${Env:ORACLE_HOME}/OPatch;${Env:PATH}"
$JRE               = 'D:\psoft\java\jdk'
${Env:PS_HOME}     = 'D:\psoft\ps_home\pt85610'

& opatch version
& opatch lsinventory -jre $JRE

# NOTE: Following DOESN'T work in Powershell ISE!
cmd /c ${Env:JRE}\bin\java.exe -version

# Backup Directories
${Env:CPU}           = 'CPU-2019-July'
${Env:CPU_BKP_Dir}   = "D:/psoft/patches/${CPU}/backups"
cmd /c robocopy /mir 

rename-item -path ${Env:JRE} -NewName ${Env:JRE}-${Env:CPU_BKP_SFX}

$CPU = 'CPU-2019-July'
$CPU_BKP_Dir = "D:/psoft/patches/${CPU}/backups"

if ( !( Test-Path -Path ${CPU_BKP_Dir} ) ) {
  New-Item -ItemType directory -Path ${CPU_BKP_Dir}
}

$CPU_LOG_Dir = "D:/psoft/patches/${CPU}/logs"
if ( !( Test-Path -Path ${CPU_LOG_Dir} ) ) {
  New-Item -ItemType directory -Path ${CPU_LOG_Dir}
}



# Backup Weblogic Directory

Write-Host "Backing Up WebLogic Directory" -ForegroundColor Green

$SRC_Dir  = 'D:\psoft\oracle\weblogic'
$TGT_Dir  = "${CPU_BKP_Dir}/weblogic"
$LOG_File = "${CPU_LOG_Dir}/weblogic_robocopy.log"

#if ( !( Test-Path -Path $TGT_Dir ) ) {
#  New-Item -ItemType directory -Path $TGT_Dir
#}

robocopy /mir /log+:$LOG_File $SRC_Dir $TGT_Dir
get-content -tail 10 $LOG_File

Write-Output '######################################################'
Write-Output '# Patch JAVA                                         #'
Write-Output '######################################################'
# Change To Patch Directory and Unzip Patch
$CPU = 'CPU-2019-July'
$CPU_Patch_Dir = "D:\psoft\patches\${CPU}\software\java"
$Patch_Zip_File = "${CPU_Patch_Dir}\p18143322_1800_MSWIN-x86-64.zip"
$JDK_Install_Exe = 'jdk-8u221-windows-x64.exe'
$JDK_Dir = 'D:\psoft\java\jdk'
$LOG_File = $CPU_LOG_Dir+'/'+$JDK_Install_Exe.split('.')[0]+"-Install.log"

set-location $CPU_Patch_Dir
Write-Host "Unzipping ${Patch_Zip_File} ..." -ForegroundColor Green
& $JDK_Dir\bin\jar.exe xvf $Patch_Zip_File
Write-Host "Initiating ${$JDK_Install_Exe} ..." -ForegroundColor Green
& ./$JDK_Install_Exe INSTALLDIR=$JDK_Dir /s /L $LOG_File
Write-Host "Waiting for ${JDK_Install_Exe} to start ..." -ForegroundColor Green
Start-Sleep -seconds 15 # Wait for exe to start
Write-Host "Waiting for ${JDK_Install_Exe} to finish ..." -ForegroundColor Green
Wait-Process jdk-8u221-windows-x64 # Wait for exe to finish

# Confirm Install Was Successful
if ( $(Select-String -Pattern 'Installation operation completed successfully' -Path $LOG_File -Quiet) -ne $true ) {
  Write-Host "Java Installation Successful - see log file $LOG_File" -ForegroundColor Green
} else {
  Write-Host "Java Installation Failed (see log file $LOG_File)" -ForegroundColor Red
  Break
}

Write-Output '######################################################'
Write-Output '# Patch OPatch                                       #'
Write-Output '######################################################'

$CPU = 'CPU-2019-July'
${Env:ORACLE_HOME} = 'D:\psoft\oracle\weblogic'
${Env:PATH} = "${Env:ORACLE_HOME}/OPatch;${Env:PATH}"
$CPU_Patch_Dir = "D:\psoft\patches\${CPU}\software\OPatch"
set-location -path $CPU_Patch_Dir

$Patch_File = 'p28186730_139400_Generic.zip'
$Patch_ID = '6880880'
$JDK_Dir = 'D:\psoft\java\jdk'
& $JDK_Dir\bin\jar.exe xvf $Patch_File
set-location -path ./$Patch_ID
#& opatch apply -jre $JDK_Dir -oop
${Env:PATH} = "D:\psoft\java\jdk\bin;${Env:PATH}"
java -jar opatch_generic.jar -J-Doracle.installer.oh_admin_acl=true -silent oracle_home=D:\psoft\oracle\weblogic
# opatch rollback -id $Patch_ID

# Run following as ADMIN from a DOS Commmand Window
cd /d D:\psoft\patches\CPU-2019-July\software\opatch\6880880
set PATH=D:\psoft\java\jdk\bin;%PATH%
java -jar opatch_generic.jar -J-Doracle.installer.oh_admin_acl=true -silent oracle_home=D:\psoft\oracle\weblogic






