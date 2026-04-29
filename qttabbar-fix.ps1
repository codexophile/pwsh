. "C:\mega\IDEs\powershell\#lib\functions.ps1"
RunAsAdmin

# Create a system restore point before making any changes
Write-Host "`n--- Creating System Restore Point ---" -ForegroundColor Cyan
try {
	$restorePointDescription = "QTTabBar Fix - ViVeTool and Registry Modifications"
	Checkpoint-Computer -Description $restorePointDescription -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
	Write-Host "SUCCESS: System restore point created: '$restorePointDescription'" -ForegroundColor Green
} catch {
	Write-Warning "Could not create system restore point: $_"
	$proceed = Read-Host "Continue anyway? (Y/N)"
	if ($proceed -notmatch '^(?i)y(?:es)?$') {
		Write-Host "Exiting script." -ForegroundColor Yellow
		Exit
	}
}

$viveToolPath = Join-Path $env:SystemDrive "Program Files (Portable)\ViVeTool\ViVeTool.exe"

if (-not (Test-Path -LiteralPath $viveToolPath -PathType Leaf)) {
	Write-Warning "ViVeTool.exe was not found at: $viveToolPath"
	$openViveRepo = Read-Host "Open https://github.com/thebookisclosed/ViVe now? (Y/N)"

	if ($openViveRepo -match '^(?i)y(?:es)?$') {
		Start-Process "https://github.com/thebookisclosed/ViVe"
	}
	Exit
}

$viveIds = @(
	"57048216"
	"57048237"
	"58988972"
)

$allSucceeded = $true

Write-Host "`n--- Starting ViVeTool modifications ---" -ForegroundColor Cyan
foreach ($id in $viveIds) {
	& $viveToolPath /disable /id:$id
	$commandExitCode = $LASTEXITCODE

	if ($commandExitCode -eq 0) {
		Write-Host "SUCCESS: vivetool /disable /id:$id"
	}
	else {
		Write-Warning "FAILED (exit code $commandExitCode): vivetool /disable /id:$id"
		$allSucceeded = $false
	}
}

if ($allSucceeded) {
	Write-Host "ViVeTool changes completed successfully." -ForegroundColor Green
}
else {
	Write-Warning "One or more ViVeTool commands failed."
}

# 1. Enable SeTakeOwnershipPrivilege
$privilegeCode = @"
using System;
using System.Runtime.InteropServices;
public class TokenPrivilege {[DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TOKEN_PRIVILEGES newst, int len, IntPtr prev, IntPtr relen);[DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);[DllImport("advapi32.dll", SetLastError = true)]
    internal static extern bool LookupPrivilegeValue(string host, string name, ref LUID pluid);
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct TOKEN_PRIVILEGES {
        public int PrivilegeCount;
        public LUID Privileges;
        public int Attributes;
    }
    [StructLayout(LayoutKind.Sequential)]
    internal struct LUID {
        public uint LowPart;
        public int HighPart;
    }
    public static void EnableTakeOwnership() {
        IntPtr hToken = IntPtr.Zero;
        if (OpenProcessToken(System.Diagnostics.Process.GetCurrentProcess().Handle, 0x0028, ref hToken)) {
            TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES();
            tp.PrivilegeCount = 1;
            tp.Attributes = 2; // SE_PRIVILEGE_ENABLED
            if (LookupPrivilegeValue(null, "SeTakeOwnershipPrivilege", ref tp.Privileges)) {
                AdjustTokenPrivileges(hToken, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
            }
        }
    }
}
"@
try {
    Add-Type -TypeDefinition $privilegeCode -ErrorAction SilentlyContinue
    [TokenPrivilege]::EnableTakeOwnership()
} catch {}

$registryIds = @("815149711", "5077241", "4070466697", "1519792783", "1482552975")
$baseRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides"
$adminGroup = New-Object System.Security.Principal.NTAccount("Administrators")

Write-Host "`n--- Starting Registry Key Fixes (Using .NET Method) ---" -ForegroundColor Cyan

# Find keys and select only unique paths to prevent duplicates
$keysToDelete = Get-ChildItem -Path $baseRegPath -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $registryIds -contains $_.PSChildName } | 
    Select-Object -Unique PSPath, Name

if ($keysToDelete.Count -eq 0) {
    Write-Host "No matching registry keys found. They may already be deleted." -ForegroundColor Yellow
} else {
    foreach ($key in $keysToDelete) {
        $regName = ($key.Name -split '\\')[-1]
        $subKeyPath = $key.Name -replace '^HKEY_LOCAL_MACHINE\\', ''
        
        Write-Host "Processing Registry Key: $regName"
        
        try {
            # Step A: Explicitly request ONLY TakeOwnership rights
            $regKeyOwner = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($subKeyPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::TakeOwnership)
            if ($null -eq $regKeyOwner) { throw "Could not open key to Take Ownership." }
            
            $acl = $regKeyOwner.GetAccessControl()
            $acl.SetOwner($adminGroup)
            $regKeyOwner.SetAccessControl($acl)
            $regKeyOwner.Close()

            # Step B: Re-open with Permission Changing rights
            $regKeyPerms = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($subKeyPath,[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions)
            $acl = $regKeyPerms.GetAccessControl()
            $accessRule = New-Object System.Security.AccessControl.RegistryAccessRule($adminGroup, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.SetAccessRule($accessRule)
            $regKeyPerms.SetAccessControl($acl)
            $regKeyPerms.Close()

            # Step C: Delete the key
            [Microsoft.Win32.Registry]::LocalMachine.DeleteSubKeyTree($subKeyPath, $false)
            
            Write-Host "SUCCESS: Deleted registry key $regName" -ForegroundColor Green
        }
        catch {
            Write-Host "FAILED: $_" -ForegroundColor Red
        }
    }
}

Write-Host "`nAll operations completed. Please RESTART your computer for changes to take effect!" -ForegroundColor Magenta
Pause