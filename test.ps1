Add-Type -AssemblyName PresentationFramework

# Create the XAML reader
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="YouTube Downloader" Height="200" Width="400"
    WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <TextBlock Grid.Row="0" Text="Downloading video..." Margin="0,0,0,10"/>
        <ProgressBar Grid.Row="1" Name="DownloadProgress" Height="20" Minimum="0" Maximum="100"/>
        <TextBlock Grid.Row="2" Name="StatusText" Margin="0,10,0,0" TextWrapping="Wrap"/>
    </Grid>
</Window>
"@

$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$progressBar = $window.FindName("DownloadProgress")
$statusText = $window.FindName("StatusText")

# Create a synchronized hashtable to share data between runspaces
$sync = [hashtable]::Synchronized(@{
    ProgressBar = $progressBar
    StatusText  = $statusText
    Window      = $window
    Completed   = $false
  })

# Create and start a new runspace for the download
$runspace = [runspacefactory]::CreateRunspace()
$runspace.ApartmentState = "STA"
$runspace.ThreadOptions = "ReuseThread"
$runspace.Open()
$runspace.SessionStateProxy.SetVariable('sync', $sync)

$downloadJob = [powershell]::Create().AddScript({
    # Sample video URL - replace with your desired URL
    $videoUrl = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    $ytDlpPath = "D:\Program Files - Portable\youtube-dl\yt-dlp.exe"
    
    # Create process start info
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ytDlpPath
    $psi.Arguments = "--newline --progress-template `"progress:%(progress._percent_str)s`" $videoUrl"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.CreateNoWindow = $true
    
    try {
      # Start the process
      $process = New-Object System.Diagnostics.Process
      $process.StartInfo = $psi
      $process.Start() | Out-Null
        
      # Read output line by line
      while (!$process.StandardOutput.EndOfStream) {
        $line = $process.StandardOutput.ReadLine()
            
        if ($line.StartsWith("progress:")) {
          $percentStr = $line.Substring(9).Trim(' %')
          $percent = [double]$percentStr
                
          # Update UI elements on the UI thread
          $sync.Window.Dispatcher.Invoke([action] {
              $sync.ProgressBar.Value = $percent
              $sync.StatusText.Text = "Downloaded: $percentStr%"
            })
        }
      }
        
      # Wait for process to complete
      $process.WaitForExit()
        
      # Update UI on completion
      $sync.Window.Dispatcher.Invoke([action] {
          $sync.StatusText.Text = "Download complete!"
          $sync.Completed = $true
        })
    }
    catch {
      $sync.Window.Dispatcher.Invoke([action] {
          $sync.StatusText.Text = "Error: $_"
          $sync.Completed = $true
        })
    }
  })

$downloadJob.Runspace = $runspace
$handle = $downloadJob.BeginInvoke()

# Add window closing event handler
$window.Add_Closed({
    if (-not $sync.Completed) {
      $downloadJob.Stop()
    }
    $runspace.Close()
    $runspace.Dispose()
  })

# Show the window
$window.ShowDialog() | Out-Null