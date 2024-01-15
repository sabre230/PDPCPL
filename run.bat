:: All this does is make it easier to launch the update script and allow unsigned scripts for this one session
:: You will need Powershell 5 or greater to run this
pushd %~dp0
start powershell -executionpolicy bypass -windowstyle hidden -noninteractive -nologo -file "update.ps1"