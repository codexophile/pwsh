Clear-Host

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

set-location $PSScriptRoot
. .\#lib\functions.ps1

function Confirm-WPF {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # Check if file exists
        if (-not (Test-Path -Path $FilePath)) {
            throw "File not found: $FilePath"
        }

        # Check file extension
        if ([System.IO.Path]::GetExtension($FilePath) -ne '.xaml') {
            throw "Invalid file extension. File must be a .xaml file."
        }

        # Read XAML content
        $xamlContent = Get-Content -Path $FilePath -Raw

        # Try to parse as XML first for basic structure validation
        try {
            [xml]$xmlContent = $xamlContent
        }
        catch {
            throw "Invalid XML structure in XAML: $($_.Exception.Message)"
        }

        # Get the root element
        $rootElement = $xmlContent.DocumentElement

        # Simplified root element check - just verify it's a Window or Page
        if ($rootElement.LocalName -notmatch '^(Window|Page)$') {
            throw "Invalid XAML: Root element must be Window or Page"
        }

        # Basic namespace check - just verify presentation namespace exists somewhere
        $hasPresentation = $false
        foreach ($attr in $rootElement.Attributes) {
            if ($attr.Value -eq 'http://schemas.microsoft.com/winfx/2006/xaml/presentation') {
                $hasPresentation = $true
                break
            }
        }

        if (-not $hasPresentation) {
            throw "Missing WPF presentation namespace"
        }

        # Check for basic WPF structure (should have some kind of layout container)
        $basicContainers = @('Grid', 'StackPanel', 'DockPanel', 'Canvas', 'WrapPanel', 'UniformGrid')
        $hasContainer = $false
        foreach ($container in $basicContainers) {
            if ($xamlContent -match "<$container[\s>]") {
                $hasContainer = $true
                break
            }
        }

        if (-not $hasContainer) {
            throw "No layout container found in XAML"
        }

        # Inventory of used controls (for information purposes)
        $commonControls = @(
            'Button', 'TextBox', 'Label', 'ComboBox', 'CheckBox', 
            'RadioButton', 'ListBox', 'DataGrid', 'Menu', 'StackPanel',
            'Grid', 'Canvas', 'Border', 'Image', 'GroupBox', 'DockPanel',
            'TextBlock', 'UniformGrid'
        )

        $usedControls = @()
        foreach ($control in $commonControls) {
            if ($xamlContent -match "<$control[\s>]") {
                $usedControls += $control
            }
        }

        # Return success result
        $result = @{
            IsValid      = $true
            FilePath     = $FilePath
            UsedControls = $usedControls
            FileSize     = (Get-Item $FilePath).Length
            LastModified = (Get-Item $FilePath).LastWriteTime
            Message      = "XAML file is valid and contains proper WPF structure."
        }

        return [PSCustomObject]$result
    }
    catch {
        $result = @{
            IsValid  = $false
            FilePath = $FilePath
            Error    = $_.Exception.Message
            Message  = "XAML validation failed: $($_.Exception.Message)"
        }

        return [PSCustomObject]$result
    }
}

# Form UI setup
$form = New-Object System.Windows.Forms.Form
$form.Text = "Drop XAML Files Here"
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.AllowDrop = $true

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.Dock = "Fill"
$outputBox.ReadOnly = $true
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$form.Controls.Add($outputBox)

$form.Add_DragEnter({
        if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
            $_.Effect = 'Copy'
        }
    })

$form.Add_DragDrop({
        $files = $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
        $outputBox.Clear()
        foreach ($file in $files) {
            $outputBox.AppendText("Processing file: $file`r`n")
            try {
                $fileInfo = Get-Item $file
                $outputBox.AppendText("Size: $($fileInfo.Length) bytes`r`n")
                $outputBox.AppendText("Last Modified: $($fileInfo.LastWriteTime)`r`n")
                $outputBox.AppendText("-------------------`r`n")

                $ValidationResult = Confirm-WPF -FilePath $file
                $outputBox.AppendText("Validation Result: $($ValidationResult.IsValid)`r`n")
                $outputBox.AppendText("Message: $($ValidationResult.Message)`r`n")
                if (-not $ValidationResult.IsValid) {
                    $outputBox.AppendText("Error: $($ValidationResult.Error)`r`n")
                }
                else {
                    $outputBox.AppendText("Used Controls: $($ValidationResult.UsedControls -join ', ')`r`n")
                    $WPFWindow = GuiFromXaml -XamlTextOrXamlFile $file
                    $WPFWindow.ShowDialog()
                }
            }
            catch {
                $outputBox.AppendText("Error processing file: $_`r`n")
            }
            $outputBox.AppendText("-------------------`r`n")
        }
    })

[void]$form.ShowDialog()