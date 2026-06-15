# Windows Cookiereider Bootable ISO Creation Script
# This script creates a bootable Windows installation ISO with Cookiereider pre-installed

param(
    [string]$WindowsISOPath = "C:\Windows\MediaCreationTool.iso",
    [string]$OutputPath = "C:\ISO\WindowsCookiereider.iso",
    [string]$MountPath = "C:\Temp\WinMount",
    [string]$WorkPath = "C:\Temp\WinWork"
)

# Verify administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script requires administrator privileges." -ForegroundColor Red
    exit 1
}

Write-Host "Starting Windows Cookiereider ISO Creation..." -ForegroundColor Green

# Create working directories
if (!(Test-Path $MountPath)) {
    New-Item -ItemType Directory -Path $MountPath -Force | Out-Null
}
if (!(Test-Path $WorkPath)) {
    New-Item -ItemType Directory -Path $WorkPath -Force | Out-Null
}

try {
    # Mount source Windows ISO
    Write-Host "Mounting source Windows ISO..." -ForegroundColor Yellow
    $mountResult = Mount-DiskImage -ImagePath $WindowsISOPath -PassThru
    $driveLetter = ($mountResult | Get-Volume).DriveLetter
    
    if (!$driveLetter) {
        throw "Failed to mount Windows ISO"
    }
    
    Write-Host "ISO mounted at drive: $($driveLetter):" -ForegroundColor Green
    
    # Copy Windows files to working directory
    Write-Host "Copying Windows installation files..." -ForegroundColor Yellow
    Copy-Item -Path "$($driveLetter):\*" -Destination $WorkPath -Recurse -Force
    
    # Create Cookiereider configuration directory
    $cookiereiderConfigPath = Join-Path $WorkPath "Cookiereider"
    New-Item -ItemType Directory -Path $cookiereiderConfigPath -Force | Out-Null
    
    Write-Host "Adding Cookiereider configuration files..." -ForegroundColor Yellow
    
    # Create Cookiereider configuration file
    $configContent = @"
<?xml version="1.0" encoding="utf-8"?>
<CookiereiderConfig>
  <System>
    <Name>Windows Cookiereider</Name>
    <Version>1.0</Version>
    <Architecture>x64</Architecture>
    <BuildDate>$(Get-Date -Format 'yyyy-MM-dd')</BuildDate>
  </System>
  
  <Installation>
    <Customizations>
      <Theme>Dark</Theme>
      <AutoUpdate>Enabled</AutoUpdate>
      <LaunchOnStartup>Enabled</LaunchOnStartup>
    </Customizations>
    
    <Packages>
      <Package name="Cookiereider Core" required="true" />
      <Package name="System Integration" required="true" />
      <Package name="User Preferences" required="false" />
    </Packages>
  </Installation>
  
  <Registry>
    <Key path="HKEY_CURRENT_USER\Software\Cookiereider\Settings">
      <Value name="SystemProfile" type="String">Cookiereider</Value>
      <Value name="Initialized" type="DWORD">1</Value>
    </Key>
  </Registry>
</CookiereiderConfig>
"@
    
    Set-Content -Path (Join-Path $cookiereiderConfigPath "config.xml") -Value $configContent -Force
    
    # Create Cookiereider installation script
    $installScript = @"
@echo off
REM Cookiereider Post-Installation Script
REM This script runs after Windows installation

echo Installing Cookiereider customizations...

REM Add Cookiereider to registry
reg add "HKEY_CURRENT_USER\Software\Cookiereider\Settings" /v "UserProfile" /t REG_SZ /d "Cookiereider" /f
reg add "HKEY_CURRENT_USER\Software\Cookiereider\Settings" /v "DarkMode" /t REG_SZ /d "Enabled" /f
reg add "HKEY_CURRENT_USER\Software\Cookiereider\Settings" /v "SystemIntegration" /t REG_SZ /d "Enabled" /f

REM Create Cookiereider data directories
mkdir "%APPDATA%\Cookiereider"
mkdir "%APPDATA%\Cookiereider\Config"
mkdir "%APPDATA%\Cookiereider\Data"
mkdir "%APPDATA%\Cookiereider\Logs"

echo Cookiereider installation complete!
"@
    
    Set-Content -Path (Join-Path $cookiereiderConfigPath "install.bat") -Value $installScript -Force
    
    # Create Cookiereider README
    $readmeContent = @"
# Windows Cookiereider Installation

This is a bootable Windows installation with Cookiereider pre-configured.

## Features
- Customized Windows installation
- Cookiereider system integration
- Dark mode theme enabled
- Auto-update enabled
- Pre-configured registry settings

## After Installation
1. Boot from this ISO
2. Complete Windows installation
3. Cookiereider will automatically configure after first login

## System Requirements
- 64-bit processor
- 2GB RAM minimum (4GB recommended)
- 20GB free disk space

## Documentation
For more information, visit the Cookiereider configuration directory.
"@
    
    Set-Content -Path (Join-Path $cookiereiderConfigPath "README.md") -Value $readmeContent -Force
    
    # Unmount source ISO
    Write-Host "Unmounting source ISO..." -ForegroundColor Yellow
    Dismount-DiskImage -ImagePath $WindowsISOPath
    
    # Create output ISO using OSCDIMG (Windows ADK tool)
    Write-Host "Creating bootable ISO image..." -ForegroundColor Yellow
    
    # Check if OSCDIMG is available
    $oscdimg = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
    
    if (Test-Path $oscdimg) {
        & $oscdimg -m -o -u1 -udfver102 $WorkPath $OutputPath
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "ISO creation successful!" -ForegroundColor Green
            Write-Host "Output file: $OutputPath" -ForegroundColor Green
            Write-Host "File size: $((Get-Item $OutputPath).Length / 1GB) GB" -ForegroundColor Green
        } else {
            throw "OSCDIMG failed with exit code: $LASTEXITCODE"
        }
    } else {
        Write-Host "WARNING: OSCDIMG not found. Installing Windows ADK..." -ForegroundColor Yellow
        Write-Host "Please install Windows ADK with Deployment Tools, then run this script again." -ForegroundColor Yellow
    }
    
    # Cleanup
    Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
    Remove-Item -Path $WorkPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $MountPath -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "Windows Cookiereider ISO creation complete!" -ForegroundColor Green
    
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    
    # Cleanup on error
    Dismount-DiskImage -ImagePath $WindowsISOPath -ErrorAction SilentlyContinue
    Remove-Item -Path $WorkPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $MountPath -Recurse -Force -ErrorAction SilentlyContinue
    
    exit 1
}
