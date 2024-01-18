# Install .NET assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
# .Net methods for hiding/showing the console in the background
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
# Enable Visual Styles
[Windows.Forms.Application]::EnableVisualStyles()



#region Variables
$rootFolder = "./"
$appName = "Small but Perfect Launcher"
$githubUrl = "https://github.com/fgsfdsfgs/perfect_dark/commits/#branch#.atom"
#$zipUrl = "https://drive.google.com/uc?export=download&id=1R6DVMnj1yfA3n7RliX-zinwiSb4C8N0E" 		# Fixed address; for testing
$zipUrl = "https://nightly.link/fgsfdsfgs/perfect_dark/workflows/c-cpp/#branch#/pd-i686-windows.zip" 	# Dynamic address; for field
$zipFile = "pd-i686-windows.zip"
$commitFile = 'current-commit.txt'
$latestID = ""
$desiredBranch = "no branch"
$defaultBranch = "port"
$canPlay = $false
#endregion

#region Tooltip object
$tooltip = New-Object System.Windows.Forms.Tooltip
# Switch statement to handle tooltips based on control names
$ShowTip = 
{
	Switch ($this.name) 
	{
		#"authTextBox"		{$tip = "Enter your GitHub Personal Access Token here to prevent rate limiting"}
		"comboBox"			{$tip = "Select a branch"}
		"updateButton" 		{$tip = "Check for updates"}
		"playButton" 		{$tip = "Play the Perfect Dark PC port"}
	}
	$tooltip.SetToolTip($this, $tip)
}
#endregion

# We need to create a webclient at some point

#region Main
function Main
{
	# Bulk of the code goes here
	############################################## MAIN METHOD
	# Make sure there's a local commit file ready to go
	Create-Local-Commit
	
	#region GUI CONTROLS
	# FORM 
	$form = New-Object System.Windows.Forms.Form
	$form.Text = $appName
	$form.Size = New-Object System.Drawing.Size(320, 240)
	$form.StartPosition = 'CenterScreen'
	$form.FormBorderStyle = 'FixedDialog'
	$form.MaximizeBox = $false
	$form.MinimizeBox = $false
	# FORM ICON; this is required to pack it when creating the executable
	$icon = 'pd.ico'
	$iconBase64 = [Convert]::ToBase64String((Get-Content $icon -Encoding Byte))
	$iconBytes = [Convert]::FromBase64String($iconBase64)
	$stream = [System.IO.MemoryStream]::new($iconBytes, 0, $iconBytes.Length)
	$form.Icon = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap]::new($stream).GetHIcon()))
	
	# UPDATE BUTTON
	$updateButton = New-Object System.Windows.Forms.Button
	$updateButton.name = "updateButton"
	$updateButton.Location = New-Object System.Drawing.Point(10, 20)
	$updateButton.Size = New-Object System.Drawing.Size(75, 23)
	$updateButton.Text = 'Update'
	
	# CLOSE BUTTON
	$closeButton = New-Object System.Windows.Forms.Button
	$closeButton.Name = "closeButton"
	$closeButton.Location = New-Object System.Drawing.Point(195, 20)
	$closeButton.Size = New-Object System.Drawing.Size(75, 23)
	$closeButton.Text = 'Close'
	$closeButton.Add_Click({ $form.Close() })

	# PLAY BUTTON
	$playButton = New-Object System.Windows.Forms.Button
	$playButton.name = "playButton"
	$playButton.Location = New-Object System.Drawing.Point(10, 80)
	$playButton.Size = New-Object System.Drawing.Size(75, 23)
	$playButton.Text = 'Play'
	$playButton.Enabled = $false
		
	# PROGRESS BAR
	$progressBar = New-Object System.Windows.Forms.ProgressBar
	$progressBar.Style = 'Continuous'
	$progressBar.Location = New-Object System.Drawing.Point(10, 130)
	$progressBar.Size = New-Object System.Drawing.Size(260, 20)
	$progressBar.Dock = 'Bottom'

	# COMBO BOX
	$comboBox = New-Object System.Windows.Forms.comboBox
	$comboBox.name = "comboBox"
	$comboBox.Location = New-Object System.Drawing.Point(103, 21)
	$comboBox.Size = New-Object System.Drawing.Size(75, 20)
	$comboBox.DropDownStyle = 'DropDownList'
	$comboBox.Height = 24
	# Add branches to the combo box
	$comboBox.Items.Add('port')
	$comboBox.Items.Add('port-net')
	$comboBox.Items.Add('port-debug')
	$comboBox.Text = $defaultBranch
	
	# AUTH TEXT BOX
	$authTextBox = New-Object System.Windows.Forms.TextBox
	$authTextBox.name = "authTextBox"
	$authTextBox.Location = New-Object System.Drawing.Point(11, 50)
	$authTextBox.Size = New-Object System.Drawing.Size(258, 20)
	
	# STATUS UPDATE LABEL
	$statusLabel = New-Object System.Windows.Forms.Label
	$statusLabel.name = "statusLabel"
	$statusLabel.Text = "No status"
	$statusLabel.AutoSize = $true
	$statusLabel.Location = New-Object System.Drawing.Point(11, 120)
	
	
    Initialize-Controls
	#endregion


	#region TOOLTIPS
	$playButton.Add_MouseHover($ShowTip)
	$closeButton.Add_MouseHover($ShowTip)
	$updateButton.Add_MouseHover($ShowTip)
	$comboBox.Add_MouseHover($ShowTip)
	#$authTextBox.Add_MouseHover($ShowTip)
	#endregion
	
	
	#region  WEBCLIENT
	$webClient = New-Object System.Net.WebClient
	#endregion
	
	
	#region events 
	$form.Add_Activated({ Event-Form-Activated })
	$form.Add_Shown({ Event-Form-Shown })
	$comboBox.Add_SelectedValueChanged({ Event-ComboBox-ValueChanged })
	$updateButton.Add_Click({ Event-UpdateButton-Clicked })
	$playButton.Add_Click({ Event-PlayButton-Clicked })
	$authTextBox.Add_TextChanged({ Event-Form-Activated	})
	#endregion
	
	$form.ShowDialog()
}
#endregion



#region Functions
function Load-Functions
{
	############################################## FUNCTIONS
	# Generic replace string function
	function Replace-String 
	{
		Param($Value, $Source, $Dest)
		
		$Out = $Value.Replace($Source, $Dest)
		return $Out
	}
	
	function Create-Local-Commit
	{		
		# If it doesn't exist, make one with a placeholder inside
		if (!(Test-Path -Path $commitFile)) 
		{
			Write-Host "No latest-commit.txt found, making one with placeholder values"
			Set-Content -Path $commitFile -Value 'null'
			return
		}
	}
	
	# Enables applicable controls
	function Enable-Controls
	{
		$playButton.Enabled = $canPlay
		$authTextBox.Enabled = $true
		$updateButton.Enabled = $true
		$closeButton.Enabled = $true
		$comboBox.Enabled = $true
	}
	
	# Disables applicable controls
	function Disable-Controls
	{
		$playButton.Enabled = $canPlay
		$authTextBox.Enabled = $false
		$updateButton.Enabled = $false
		$closeButton.Enabled = $false
		$comboBox.Enabled = $false
	}
	
	# Update the status label text
	function Status-Update 
	{
		Param($s)
		$statusLabel.Text = $s
	}
	
	function Check-For-Update
	{
		# need to have network checks in place
		try
		{
			# Download the repo Atom feed and convert it to an XML object
			$branchGithubUrl = $githubUrl.Replace('#branch#', $comboBox.Text)
			$atomFeed = [xml]$webClient.DownloadString($branchGithubUrl)

			# Get the Atom namespace
			$ns = New-Object Xml.XmlNamespaceManager $atomFeed.NameTable
			$ns.AddNamespace("ns", "http://www.w3.org/2005/Atom")
			
			# Get our local and online IDs
			$currentID = Get-Content -Path $commitFile
			$latestID = ($atomFeed.SelectSingleNode("/ns:feed/ns:entry[1]/ns:id", $ns).'#text' -split 'Grit::Commit/')[-1]
			
			if ($currentID -ne $latestID)
			{
				# Update our local commmit with the most recent one we found
				Set-Content -Path "current-commit.txt" -Value $latestID
			
				# Change the URL for the specified branch
				$branchZipUrl = $zipUrl.Replace('#branch#', $comboBox.Text)
				# Download the zip from the new address
				Write-Host "Downloading from: $branchZipUrl"
				$webClient.DownloadFileAsync($branchZipUrl, $zipFile)
				
				Unpack-Update
			}
			else
			{
				Status-Update -s "No update required"
				Write-Host "Everything is up to date, no update required"
				
				Enable-Controls
				$progressBar.Style = 'Continuous'
				$progressBar.Value = 100
				$updateButton.Text = 'Update'
			}
		}
		catch
		{
			$string_err = $_ | Out-String
			write-host $string_err
			Show-Console
		}
	}
	
	function Unpack-Update
	{
		$webClient.Add_DownloadFileCompleted({ param($sender, $e)
		
			Write-Host "Download has finished"
				
			try 
			{
				# Unpack zip archive and move contents to the parent folder, cleaning up as we go
				Expand-Archive -Path $zipFile -Force
				Remove-Item -Path $zipFile	
				
				Get-ChildItem -Path ".\pd-i686-windows" | Copy-Item -Destination ".\" -Recurse -Force
				Remove-Item -Path "pd-i686-windows" -Force -Recurse
			} 
			catch 
			{
				$string_err = $_ | Out-String
				write-host $string_err
				Show-Console
			} 
			
			# Check to see if the ROM is already available; is this a first-time use or a repeat use?
			if (Test-Path ".\data\pd.ntsc-final.z64")
			{
				# This is a repeat use; the ROM would've been there before updating
				$canPlay = $true
				Write-Host "All done!"
			}
			else
			{					
				# This is a first-time use; odds are low the user would already have a "data" folder handy
				$canPlay = $false
				Write-Host ""
				Status-Update -s "ROM file is missing from data folder!"
			}
			
			# We are now done with unpacking
			# Clean things up for the user
			Enable-Controls

			$progressBar.Style = 'Continuous'
			$progressBar.Value = 100
			$updateButton.Text = 'Update'
		})
		#}
	}		
	
	# Initialize all controls
	function Initialize-Controls
	{
		$form.Controls.Add($playButton)
		$form.Controls.Add($closeButton)
		$form.Controls.Add($updateButton)
		$form.Controls.Add($comboBox)
		#$form.Controls.Add($authTextBox)
		$form.Controls.Add($statusLabel)
		$form.Controls.Add($progressBar)
	}
	
	# Console functions
	function Show-Console
	{
		$consolePtr = [Console.Window]::GetConsoleWindow()

		#region parameters
		
		# Hide = 0,
		# ShowNormal = 1,
		# ShowMinimized = 2,
		# ShowMaximized = 3,
		# Maximize = 3,
		# ShowNormalNoActivate = 4,
		# Show = 5,
		# Minimize = 6,
		# ShowMinNoActivate = 7,
		# ShowNoActivate = 8,
		# Restore = 9,
		# ShowDefault = 10,
		# ForceMinimized = 11
		
		#endregion

		[Console.Window]::ShowWindow($consolePtr, 4)
	}

	function Hide-Console
	{
		$consolePtr = [Console.Window]::GetConsoleWindow()
		#0 hide
		[Console.Window]::ShowWindow($consolePtr, 0)
		
		
	}
	
	function Event-Form-Activated
	{
		# Check for the EXE and ROM files
		if ((Test-Path ".\pd.exe") -And (Test-Path ".\data\pd.ntsc-final.z64")) 
		{
			# Required files are present
			$playButton.Enabled = $true
			Write-Host "Required files are present"
			Status-Update -s "Ready to play!"
			# We can return and keep the play button enabled
		return
		}
		elseif (!(Test-Path ".\data\pd.ntsc-final.z64") -And (Test-Path ".\pd.exe"))
		{
			Write-Host "No ROM file in 'data' folder"
			Status-Update -s "ROM needs to be in the 'data' folder!"
		}
		else
		{
			# Required files are NOT present
			Write-Host "ROM and/or pd.exe are missing"
			Status-Update -s "Update required"
		}
	
		# If either files are missing, we will disable the button
		$playButton.Enabled = $false
	}
	
	function Event-Form-Shown
	{
		$form.TopMost = $true
		$form.Activate()
		$form.TopMost = $false
	}
	
	function Event-ComboBox-ValueChanged
	{
		# Our desired branch should match the combo box
		$desiredBranch = $comboBox.Text
		Write-Host "'$desiredBranch' selected"
		Status-Update -s "$desiredBranch selected"
		
		# Replace BRANCH in the string to match our desired branch
		$finalZipUrl = $zipUrl.Replace('#branch#', $desiredBranch)
		Write-Host "Target URL: $finalZipUrl"
	}
	
	function Event-UpdateButton-Clicked
	{
		$canPlay = $false
		Disable-Controls
		
		# Set the values we want to change immediately after clicking update
		$progressBar.MarqueeAnimationSpeed = 15
		$progressBar.Style = 'Marquee'
		$progressBar.Value = 0
		$updateButton.Text = 'Updating...'		


		Check-For-Update # Includes downloading and unpacking
	}
	
	function Event-PlayButton-Clicked
	{
		# If pd.exe exists
		if (Test-Path ".\pd.exe")
		{
			Write-Host "Play pd.exe"
			Status-Update -s "Have fun!"
			
			Start-Process -FilePath "pd.exe"
			$form.Close()
		}
	}
	
	function Event-Authbox-TextChanged
	{
		# Check for github token
		if ($authTextBox.Text.Length -eq '40' -And $authTextBox.Text.StartsWith('ghp_'))
		{ 
			# The token matches the structure of GitHub's personal access tokens and is probably valid
		} 
		else 
		{ 
			# Bad string
		}
	}
	
	$OnFormLoad = Hide-Console
}
#endregion



#region Events
#function Load-Events
#{
	############################################## EVENTS
	
		# When the form is activated or brought into focus


#}
#endregion


#region App initialization
# Initialize main and functions
. Load-Functions
#Load-Events
. Main
#endregion

#region App cleanup
# We are done with everything
$stream.Dispose()
$Form.Dispose()

# Bring the console back up for debugging (very last)
Show-Console
#endregion

# Generic catch boilerplate
# catch 
# {
	# Write-Host ("Caught an exception in line: " + $_.InvocationInfo.ScriptLineNumber)
	# Write-Host ("Error details: " + $_.Exception | Format-List -Force)
# }