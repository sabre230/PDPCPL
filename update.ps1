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
$githubUrl = "https://github.com/fgsfdsfgs/perfect_dark/commits/port-net.atom"
#$zipUrl = "https://drive.google.com/uc?export=download&id=1R6DVMnj1yfA3n7RliX-zinwiSb4C8N0E" 		# Fixed address; for testing
$zipUrl = "https://nightly.link/fgsfdsfgs/perfect_dark/workflows/c-cpp/#branch#/pd-i686-windows.zip" 	# Dynamic address; for field
$zipFile = "pd-i686-windows.zip"
$commitFile = ""
$latestID = ""
$desiredBranch = "no branch"
$defaultBranch = "port"
#endregion

#region Form object
$form = New-Object System.Windows.Forms.Form
$form.Text = $appName
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false

$form.Add_Activated({
	# Check for playable stuff

		if ((Test-Path ".\pd.exe") -And (Test-Path ".\data\pd.ntsc-final.z64")) 
		{
		# Required files are present
		$playButton.Enabled = $true
		Write-Host "Required files are present"
		Status-Update -s "Ready to play!"
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
	
	$playButton.Enabled = $false
})
#endregion

#region Form object icon
$icon = 'pd.ico'
$iconBase64 = [Convert]::ToBase64String((Get-Content $icon -Encoding Byte))
$iconBytes = [Convert]::FromBase64String($iconBase64)
$stream = [System.IO.MemoryStream]::new($iconBytes, 0, $iconBytes.Length)
$form.Icon = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap]::new($stream).GetHIcon()))
#endregion

#region Tooltip object
$tooltip = New-Object System.Windows.Forms.Tooltip

# Switch statement to handle tooltips based on control names
$ShowTip = 
{
	Switch ($this.name) 
	{
		"authTextBox"		{$tip = "Enter your GitHub Personal Access Token here to prevent rate limiting"}
		"comboBox"			{$tip = "Select a branch"}
		"updateButton" 		{$tip = "Check for updates"}
		"playButton" 		{$tip = "Play the Perfect Dark PC port"}
	}
	$tooltip.SetToolTip($this, $tip)
}
#endregion

#region Status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.name = "statusLabel"
$statusLabel.Text = "No status"
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(11, 120)

function Status-Update 
	{
		Param($s)
		$statusLabel.Text = $s
	}

$form.Controls.Add($statusLabel)

Status-Update -s "Waiting for you" 
#endregion

#region GitHub Personal Access Token textbox
# Add GitHub token text box
$authTextBox = New-Object System.Windows.Forms.TextBox
$authTextBox.name = "authTextBox"
$authTextBox.Location = New-Object System.Drawing.Point(11, 50)
$authTextBox.Size = New-Object System.Drawing.Size(258, 20)

$authTextBox.Add_TextChanged({
	# Check for github token
	if ($authTextBox.Text.Length -eq '40' -And $authTextBox.Text.StartsWith('ghp_'))
		{ 
			# The token matches the structure of GitHub's personal access tokens and is probably valid
		} 
		else 
		{ 
			# Bad string
		}
	})
	
$authTextBox.Add_MouseHover($ShowTip)
# Finally, add the control
$form.Controls.Add($authTextBox)
#endregion

#region Branch combobox
function Replace-String {
	Param($Value, $Source, $Dest)
	$Out = $Value.Replace($Source, $Dest)
	return $Out
}

function Download-Zip {
	Param($Url, $Dest)
}

$comboBox = New-Object System.Windows.Forms.comboBox
$comboBox.name = "comboBox"
$comboBox.Location = New-Object System.Drawing.Point(103, 21)
$comboBox.Size = New-Object System.Drawing.Size(75, 20)
$comboBox.DropDownStyle = 'DropDownList'
$comboBox.Height = 24


$comboBox.Add_SelectedValueChanged({
	$desiredBranch = $comboBox.Text
	Write-Host "Selected branch: '$desiredBranch'"
	Status-Update -s "Selected branch: $desiredBranch"
	# Replace BRANCH in the string to match our desired branch
	$finalZipUrl = $zipUrl.Replace('#branch#', $desiredBranch)
	
	#Replace-String -Value $zipUrl -Source '#branch#' -Dest $desiredBranch
	
	Write-Host "Target URL: $finalZipUrl"
	
})


[void] $comboBox.Items.Add('port')
[void] $comboBox.Items.Add('port-net')
[void] $comboBox.Items.Add('port-debug')

$form.Controls.Add($comboBox)
# Change text after the control has been added
$comboBox.Text = $defaultBranch
#endregion

#region Progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Style = 'Continuous'
$progressBar.Location = New-Object System.Drawing.Point(10, 130)
$progressBar.Size = New-Object System.Drawing.Size(260, 20)
$progressBar.Dock = "Bottom"
$form.Controls.Add($progressBar)
#endregion

#region Play button
$playButton = New-Object System.Windows.Forms.Button
$playButton.name = "playButton"
$playButton.Location = New-Object System.Drawing.Point(10, 80)
$playButton.Size = New-Object System.Drawing.Size(75,23)
$playButton.Text = 'Play'
$playButton.Enabled = $false
$form.Controls.Add($playButton)

$playButton.Add_Click({
	# If pd.exe exists
	if (Test-Path ".\pd.exe")
		{
		Write-Host "Play pd.exe"
		Status-Update -s "Have fun!"
		
		Start-Process -FilePath "pd.exe"
		$form.Close()
		}
	})
#endregion

#region Web client
# Do this when we're not feeling lazy
#endregion

#region Update button
$updateButton = New-Object System.Windows.Forms.Button
$updateButton.name = "updateButton"
$updateButton.Location = New-Object System.Drawing.Point(10, 20)
$updateButton.Size = New-Object System.Drawing.Size(75,23)
$updateButton.Text = 'Update'

$form.Controls.Add($updateButton)

$updateButton.Add_Click({		
	# Do stuff on click
	$progressBar.Value = 0
	$progressBar.Style = 'Marquee'
	$progressBar.MarqueeAnimationSpeed = 15
	$updateButton.Text = 'Updating...'
	$authTextBox.Enabled = $false
	$updateButton.Enabled = $false
	$closeButton.Enabled = $false
	$comboBox.Enabled = $false

	try {
		# Check if GitHub token is provided
		if ($authTextBox.Text -eq '') {
			Write-Host "GitHub token not provided, you may be rate-limited!"
			Status-Update -s "No token provided"
		} else {
			Write-Host "GitHub token provided: $authTextBox.Text"
			Status-Update -s "Provided token: $authTextBox.Text"
		}

		# Ensure current-commit.txt exists
		$commitFile = Join-Path -Path $rootFolder -ChildPath 'current-commit.txt'
		if (-not (Test-Path -Path $commitFile)) {
			Set-Content -Path $commitFile -Value 'null'
		}

		# Get latest commit ID
		$webClient = New-Object System.Net.WebClient
		$githubUrlWithToken = $githubUrl + "?access_token=" + $authTextBox.Text
		
		# Download the Atom feed and convert it to an XML object
		$atomFeed = [xml]$webClient.DownloadString($githubUrl)

		# Get the Atom namespace
		$ns = New-Object Xml.XmlNamespaceManager $atomFeed.NameTable
		$ns.AddNamespace("ns", "http://www.w3.org/2005/Atom")

		# Compare IDs
		$currentID = Get-Content -Path $commitFile
		$latestID = ($atomFeed.SelectSingleNode("/ns:feed/ns:entry[1]/ns:id", $ns).'#text' -split 'Grit::Commit/')[-1]
		Write-Host "Current commit ID: $currentID"
		Write-Host "Latest commit ID: $latestID"
		
		# We are checking to see if an update is ready
		if ($latestID -ne $currentID) 
		{			
			# On completing the download
			$webClient.Add_DownloadFileCompleted( {param($sender, $e)
				try 
				{
					# Unpack zip archive
					Expand-Archive -Path $zipFile -Force
					Remove-Item -Path $zipFile	
					
					# Move contents to parent folder
					Get-ChildItem -Path ".\pd-i686-windows" | Copy-Item -Destination ".\" -Recurse -Force
					Remove-Item -Path "pd-i686-windows" -Force -Recurse
					
					Write-Host "Finished!"
					Status-Update -s "Done!"	

					if ((Test-Path ".\pd.exe") -And (Test-Path ".\pd.ntsc-final.z64"))
					{
						$playButton.Enabled = $true
					}
					else
					{
						Status-Update -s "ROM needs to be in the 'data' folder!"
						$playButton.Enabled = $false
					}					
				} 
				catch 
				{
					Write-Host ("Exception on line " + $_.InvocationInfo.ScriptLineNumber)
					Write-Host ("Error: " + $_.Exception | Format-List -Force)
					Status-Update -s "Web client issues"
					return
				} 
				finally 
				{
					# After everything
					$authTextBox.Enabled = $true
					$updateButton.Enabled = $true
					$closeButton.Enabled = $true
					$progressBar.Style = 'Continuous'
					$progressBar.Value = 100
					$updateButton.Text = 'Update'
					$comboBox.Enabled = $true
				}
			})
			

			
#region shitty hack			
			#We're hacking this together because I'm tired af
			$hackText = $comboBox.Text
			$hackZipUrl = $zipUrl.Replace('#branch#', $hackText)
			# Download the zip from the specified address
			Write-Host "Downloading from --------> $hackZipUrl"
#endregion
			$webClient.DownloadFileAsync($hackZipUrl, $zipFile)
		} 
		else 
		{
			Write-Host "The current commit ID matches the latest commit ID. No action is required."
			Status-Update -s "Already on latest update"
			
			$authTextBox.Enabled = $true
			$updateButton.Enabled = $true
			$closeButton.Enabled = $true
			$progressBar.Style = 'Continuous'
			$progressBar.Value = 100
			$updateButton.Text = 'Update'
			$comboBox.Enabled = $true
			
			if ((Test-Path ".\pd.exe") -And (Test-Path ".\pd.ntsc-final.z64"))
			{
				$playButton.Enabled = $true
			}
			else
			{
				Status-Update -s "ROM needs to be in the 'data' folder!"
			}
			
		}
		Set-Content -Path "current-commit.txt" -Value $latestID
		
	} catch {
		Write-Host ("Caught an exception in line: " + $_.InvocationInfo.ScriptLineNumber)
		Write-Host ("Error details: " + $_.Exception | Format-List -Force)
	}
})
#endregion

#region Close button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Location = New-Object System.Drawing.Point(195, 20)
$closeButton.Size = New-Object System.Drawing.Size(75,23)
$closeButton.Text = 'Close'
$closeButton.Add_Click({ $form.Close() })
$form.Controls.Add($closeButton)
#endregion

#region Console functions
function Show-Console
{
    $consolePtr = [Console.Window]::GetConsoleWindow()

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

    [Console.Window]::ShowWindow($consolePtr, 4)
}

function Hide-Console
{
	$consolePtr = [Console.Window]::GetConsoleWindow()
	#0 hide
	[Console.Window]::ShowWindow($consolePtr, 0)
}

$OnFormLoad = Hide-Console
#endregion

#region Form initialization
# Ensures app shows up on top of everything else, but doesn't stay there
$form.TopMost = $true
$form.Add_Shown({
	$form.TopMost = $false
	$form.Activate()
	})

$form.ShowDialog()
#endregion

#region Cleanup
# We are done with everything
$stream.Dispose()
$Form.Dispose()
#endregion

# Bring the console back up for debugging
Show-Console
