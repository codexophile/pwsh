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
    Output      = New-Object System.Collections.ArrayList
  })

# Create and start a new runspace for the download
$runspace = [runspacefactory]::CreateRunspace()
$runspace.ApartmentState = "STA"
$runspace.ThreadOptions = "ReuseThread"
$runspace.Open()
$runspace.SessionStateProxy.SetVariable('sync', $sync)

$downloadJob = [powershell]::Create().AddScript({
    # Sample video URL - replace with your desired URL
    $videoUrl = "https://www.youtube.com/watch?v=As6QAVuEqDY"
    $ytDlpPath = "D:\Program Files - Portable\youtube-dl\yt-dlp.exe"
    
    # Create process start info
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ytDlpPath
    $psi.Arguments = "--newline --progress-template `"progress:%(progress._percent_str)s`" $videoUrl"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    
    try {
      $process = New-Object System.Diagnostics.Process
      $process.StartInfo = $psi
      $process.Start() | Out-Null
        
      while (!$process.StandardOutput.EndOfStream) {
        $line = $process.StandardOutput.ReadLine()
            
        # Add to synchronized output collection
        $sync.Output.Add($line) | Out-Null
            
        if ($line.StartsWith("progress:")) {
          $percentStr = $line.Substring(9).Trim(' %')
          $percent = [double]$percentStr
                
          $sync.Window.Dispatcher.Invoke([action] {
              $sync.ProgressBar.Value = $percent
              $sync.StatusText.Text = "Downloaded: $percentStr%"
            })
        }
      }
        
      $errorOutput = $process.StandardError.ReadToEnd()
      if ($errorOutput) {
        $sync.Output.Add("[ERROR] $errorOutput") | Out-Null
      }
        
      $process.WaitForExit()
        
      $sync.Window.Dispatcher.Invoke([action] {
          $sync.StatusText.Text = "Download complete!"
          $sync.Completed = $true
        })
      $sync.Output.Add("[SUCCESS] Download complete!") | Out-Null
    }
    catch {
      $errorMessage = "Error: $_"
      $sync.Window.Dispatcher.Invoke([action] {
          $sync.StatusText.Text = $errorMessage
          $sync.Completed = $true
        })
      $sync.Output.Add("[ERROR] $errorMessage") | Out-Null
    }
  })

$downloadJob.Runspace = $runspace
$handle = $downloadJob.BeginInvoke()

# Create a timer to check for new output
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(100)
$lastIndex = 0
$timer.Add_Tick({
    while ($lastIndex -lt $sync.Output.Count) {
      $line = $sync.Output[$lastIndex]
      if ($line.StartsWith("[ERROR]")) {
        Write-Host $line.Substring(7) -ForegroundColor Red
      }
      elseif ($line.StartsWith("[SUCCESS]")) {
        Write-Host $line.Substring(9) -ForegroundColor Green
      }
      else {
        Write-Host $line
      }
      $lastIndex++
    }
  })
$timer.Start()

# Add window closing event handler
$window.Add_Closed({
    if (-not $sync.Completed) {
      $downloadJob.Stop()
    }
    $timer.Stop()
    $runspace.Close()
    $runspace.Dispose()
  })

# Show the window
$window.ShowDialog() | Out-Null