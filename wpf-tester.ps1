Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Drop Files Here"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.AllowDrop = $true

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.Dock = "Fill"
$outputBox.ReadOnly = $true
$form.Controls.Add($outputBox)

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

        # Basic XAML syntax validation
        if (-not ($xamlContent -match '<Window.*?>.*?</Window>' -or $xamlContent -match '<Page.*?>.*?</Page>')) {
            throw "Invalid XAML: Must contain either a Window or Page root element."
        }

        # Try to parse as XML first for basic structure validation
        try {
            [xml]$xmlContent = $xamlContent
        }
        catch {
            throw "Invalid XML structure in XAML: $($_.Exception.Message)"
        }

        # Validate namespace declarations
        $requiredNamespaces = @(
            'http://schemas.microsoft.com/winfx/2006/xaml/presentation',
            'http://schemas.microsoft.com/winfx/2006/xaml'
        )

        $rootElement = $xmlContent.DocumentElement
        $hasRequiredNamespaces = $false

        foreach ($ns in $rootElement.Attributes) {
            if ($ns.Value -in $requiredNamespaces) {
                $hasRequiredNamespaces = $true
                break
            }
        }

        if (-not $hasRequiredNamespaces) {
            throw "Missing required WPF namespaces in XAML."
        }

        # Try to actually load the XAML using GuiFromXaml
        try {
            $null = GuiFromXaml -XamlTextOrXamlFile $FilePath
        }
        catch {
            throw "Failed to create WPF window: $($_.Exception.Message)"
        }

        # Validation checks for common WPF controls
        $commonControls = @(
            'Button', 'TextBox', 'Label', 'ComboBox', 'CheckBox', 
            'RadioButton', 'ListBox', 'DataGrid', 'Menu', 'StackPanel',
            'Grid', 'Canvas', 'Border', 'Image'
        )

        $usedControls = @()
        foreach ($control in $commonControls) {
            if ($xamlContent -match "<$control") {
                $usedControls += $control
            }
        }

        # Return validation results
        $result = @{
            IsValid      = $true
            FilePath     = $FilePath
            UsedControls = $usedControls
            FileSize     = (Get-Item $FilePath).Length
            LastModified = (Get-Item $FilePath).LastWriteTime
            Message      = "XAML file is valid and can be rendered as WPF GUI."
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

$form.Add_DragEnter({
        if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
            $_.Effect = 'Copy'
        }
    })

$form.Add_DragDrop({
        $files = $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
        foreach ($file in $files) {
            $outputBox.AppendText("Processing file: $file`r`n")
            try {

                # You can modify this section to handle the files however you want
                $fileInfo = Get-Item $file
                $outputBox.AppendText("Size: $($fileInfo.Length) bytes`r`n")
                $outputBox.AppendText("Last Modified: $($fileInfo.LastWriteTime)`r`n")
                $outputBox.AppendText("-------------------`r`n")

                $ValidationResult = Confirm-WPF -FilePath $file
                $outputBox.AppendText("Validation Result: $($ValidationResult.IsValid)`r`n")
            
            }
            catch {
                $outputBox.AppendText("Error processing file: $_`r`n")
            }
        }
    })

[void]$form.ShowDialog()
