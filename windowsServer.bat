@echo OFF

NET SESSION >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
   set run = account_policies audit_policies disable_services firewall
) ELSE (
   echo ------- ERROR: ADMINISTRATOR PRIVILEGES REQUIRED -------
   echo This script must be run as administrator to work properly!  
   echo --------------------------------------------------------
   echo.
   PAUSE
   EXIT /B 1
)

echo Starting...

:account_policies
echo Setting Account Policies...
net accounts /minpwlen:8
net accounts /minpwlen:8
net accounts /lockoutthreshold:5
net accounts /maxpwage:30
net accounts /uniquepw:5
net accounts /lockoutduration:30
net accounts /lockoutthreshold:5
net accounts /lockoutwindow:30

:audit_policies
echo Setting Audit Policies...
auditpol /set /category:* /success:enable
auditpol /set /category:* /failure:enable

:disable_services
echo Disabling Services...

echo Disabling Plug and Play Service...
sc config "PlugPlay" start= disabled
sc stop "PlugPlay"

echo Disabling FTP Service...
sc config "ftpsvc" start= disabled
sc stop "ftpsvc"

echo Disabling Telnet Service...
sc config "tlntsvr" start= disabled
sc stop "tlntsvr"

echo Disabling Remote Registry Service...
sc config "RemoteRegistry" start= disabled
sc stop "RemoteRegistry"

echo Disabling Remote Desktop Service...
sc config "TermService" start= disabled
sc stop "TermService"

:enable_uac
echo Enabling UAC...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f

:firewall
echo Enabling Firewall...
netsh advfirewall set allprofiles state on
netsh advfirewall reset

echo Disabling File and Printer Sharing...
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=No

echo Disabling Remote Desktop...
netsh advfirewall firewall set rule group="Remote Desktop" new enable=No

echo Disabling Remote Assistance...
netsh advfirewall firewall set rule group="Remote Assistance" new enable=No

echo All tasks completed! Manual actions may still be required.

pause