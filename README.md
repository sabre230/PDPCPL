# PDPCP Launcher

This little tool is meant to make keeping your Perfect Dark PC Port up-to-date more convenient. 


## What does PDPCPL mean?
PDPCPL is an acronym of *"Perfect Dark PC Port Launcher"*.


## Why does PDPCPL exist?
PDPCPL was born out of my own laziness. I enjoy playing the Perfect Dark PC port, but updating it to the most recent auto-built version is too many clicks for me, so instead I built a little GUI application with PowerShell and its integration with WinForms to do the work for me. I simply chose PowerShell because it's what I had immediate access to, not because it does anything particularly special.


## What does PDPCPL do?
Everything under the hood is exposed in the `update.ps1` file. You can open it in any text editor and see exactly what calls it's making and what information it stores. PDPCPL is primarily designed to:
- Download the most recent version of the auto-built Perfect Dark PC port from GitHub.
	- If the application detects a new version, it will replace the old build with the most recent version.
- Launch the game


### Okay, but what *exactly* is it doing?
- When the `Update` button is clicked, PDPCPL will query the Perfect Dark PC port Commits Atom feed. It parses the feed as an XML document, reads the most recent Commit ID, then checks against the ID stored in `current-commit.txt` file to see if the Commit IDs match.
	- If there isn't a `current-commit.txt`, PDPCPL will create one.
- Since the Perfect Dark PC port has builds auto-generated when there's a new push, checking the Commits Atom feed seemed like as good a place as any to see if there's a new build available.
	- I'm using the Atom feed specifically so the end-user doesn't need to have anything extra installed.


## How to use PDPCPL
- Run the `run.bat` batch file to start the GUI application.
- Click `Update` to download the most recent update
	- If you have a `current-commit.txt` file that is preventing an update, you can delete it and click 'Update' again to force the application to redownload the latest auto-build.
- 