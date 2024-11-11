Add-Type -AssemblyName System.Windows.Forms

# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell GUI"
$form.Size = New-Object System.Drawing.Size(300, 200)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "How would you like to proceed?"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($label)

# Create a button for 'Exit'
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "Exit"
$exitButton.Location = New-Object System.Drawing.Point(50, 70)
$exitButton.Size = New-Object System.Drawing.Size(75, 23)
$exitButton.Add_Click({ $form.Close() })
$form.Controls.Add($exitButton)

# Create a button for 'Download'
$downloadButton = New-Object System.Windows.Forms.Button
$downloadButton.Text = "Download"
$downloadButton.Location = New-Object System.Drawing.Point(150, 70)
$downloadButton.Size = New-Object System.Drawing.Size(75, 23)
$downloadButton.Add_Click({
    # Add your download logic here
    [System.Windows.Forms.MessageBox]::Show("Download functionality will be implemented here.", "Download")
})
$form.Controls.Add($downloadButton)

# Show the form
$form.Add_Shown({ $form.Activate() })
$form.ShowDialog()