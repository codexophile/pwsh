Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Drop Files Here"
$form.Size = New-Object System.Drawing.Size(400,300)
$form.AllowDrop = $true

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.Dock = "Fill"
$outputBox.ReadOnly = $true
$form.Controls.Add($outputBox)

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
        }
        catch {
            $outputBox.AppendText("Error processing file: $_`r`n")
        }
    }
})

[void]$form.ShowDialog()
