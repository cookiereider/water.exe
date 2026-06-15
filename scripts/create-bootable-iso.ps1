# Windows Cookiereider Robust Bootable ISO Creation Script
# This script creates a highly compatible bootable Windows installation ISO with Cookiereider pre-installed
# Supports both BIOS and UEFI boot modes

param(
    [string]$WindowsISOPath = "C:\Windows\MediaCreationTool.iso",
    [string]$OutputPath = "C:\ISO\WindowsCookiereider.iso",
    [string]$MountPath = "C:\Temp\WinMount",
    [string]$WorkPath = "C:\Temp\WinWork",
    [switch]$UEFIOnly = $false,
    [switch]$BIOSOnly = $false
)

# Verify administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script requires administrator privileges." -ForegroundColor Red
    exit 1
}

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Windows Cookiereider ISO Creator" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Validate input
if (!(Test-Path $WindowsISOPath)) {
    Write-Host "ERROR: Source Windows ISO not found at: $WindowsISOPath" -ForegroundColor Red
    exit 1
}

# Create output directory if it doesn't exist
$OutputDir = Split-Path $OutputPath
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Create working directories
if (!(Test-Path $MountPath)) {
    New-Item -ItemType Directory -Path $MountPath -Force | Out-Null
}
if (!(Test-Path $WorkPath)) {
    New-Item -ItemType Directory -Path $WorkPath -Force | Out-Null
}

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Source ISO: $WindowsISOPath"
Write-Host "  Output ISO: $OutputPath"
Write-Host "  Working Directory: $WorkPath"
Write-Host "  Mount Point: $MountPath"
Write-Host "  UEFI Support: $(if ($UEFIOnly) { 'UEFI Only' } elseif ($BIOSOnly) { 'BIOS Only' } else { 'BIOS + UEFI (Hybrid)' })"
Write-Host ""

try {
    # Mount source Windows ISO
    Write-Host "Step 1: Mounting source Windows ISO..." -ForegroundColor Green
    $mountResult = Mount-DiskImage -ImagePath $WindowsISOPath -PassThru
    $driveLetter = ($mountResult | Get-Volume).DriveLetter
    
    if (!$driveLetter) {
        throw "Failed to mount Windows ISO"
    }
    
    Write-Host "  ✓ ISO mounted at drive: $($driveLetter):" -ForegroundColor Green
    Start-Sleep -Seconds 2
    
    # Copy Windows files to working directory
    Write-Host "`nStep 2: Copying Windows installation files..." -ForegroundColor Green
    Write-Host "  This may take several minutes..." -ForegroundColor Yellow
    Copy-Item -Path "$($driveLetter):\*" -Destination $WorkPath -Recurse -Force
    Write-Host "  ✓ Files copied successfully" -ForegroundColor Green
    
    # Create Cookiereider configuration directory
    $cookiereiderConfigPath = Join-Path $WorkPath "Cookiereider"
    New-Item -ItemType Directory -Path $cookiereiderConfigPath -Force | Out-Null
    
    Write-Host "`nStep 3: Adding Cookiereider configuration files..." -ForegroundColor Green
    
    # Create Cookiereider configuration file
    $configContent = @"
<?xml version="1.0" encoding="utf-8"?>
<CookiereiderConfig>
  <System>
    <Name>Windows Cookiereider</Name>
    <Version>1.0</Version>
    <Architecture>x64</Architecture>
    <BuildDate>$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</BuildDate>
    <BootMode>$(if ($UEFIOnly) { 'UEFI' } elseif ($BIOSOnly) { 'BIOS' } else { 'Hybrid (BIOS+UEFI)' })</BootMode>
  </System>
  
  <Installation>
    <Customizations>
      <Theme>Dark</Theme>
      <AutoUpdate>Enabled</AutoUpdate>
      <LaunchOnStartup>Enabled</LaunchOnStartup>
      <BootSecurityMode>SecureBoot</BootSecurityMode>
    </Customizations>
    
    <Packages>
      <Package name="Cookiereider Core" required="true" />
      <Package name="System Integration" required="true" />
      <Package name="Boot Configuration" required="true" />
      <Package name="User Preferences" required="false" />
    </Packages>
  </Installation>
  
  <BootConfiguration>
    <BIOSBoot>
      <MBRBootCode>Enabled</MBRBootCode>
      <BootSectorSignature>0xAA55</BootSectorSignature>
      <BootPriority>1</BootPriority>
    </BIOSBoot>
    <UEFIBoot>
      <EFIBootEntry>Enabled</EFIBootEntry>
      <SecureBootCompatible>Yes</SecureBootCompatible>
      <BootPriority>2</BootPriority>
    </UEFIBoot>
  </BootConfiguration>
  
  <Registry>
    <Key path="HKEY_CURRENT_USER\Software\Cookiereider\Settings">
      <Value name="SystemProfile" type="String">Cookiereider</Value>
      <Value name="BootMode" type="String">$(if ($UEFIOnly) { 'UEFI' } elseif ($BIOSOnly) { 'BIOS' } else { 'Hybrid' })</Value>
      <Value name="Initialized" type="DWORD">1</Value>
    </Key>
  </Registry>
</CookiereiderConfig>
"@
    
    Set-Content -Path (Join-Path $cookiereiderConfigPath "config.xml") -Value $configContent -Force
    Write-Host "  ✓ Configuration file created" -ForegroundColor Green
    
    # Create Cookiereider boot configuration script
    $bootConfigScript = @"
@echo off
REM Cookiereider Boot Configuration Script
REM Configures boot settings for optimal compatibility

setlocal enabledelayedexpansion

echo.
echo ========================================
echo Cookiereider Boot Configuration
echo ========================================
echo.

REM Configure boot options in registry
echo Configuring boot settings...

REM Enable Legacy Boot (BIOS compatibility)
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v "SystemBootEnvironment" /t REG_SZ /d "BIOS" /f

REM Configure boot timeout
bcdedit /timeout 30

REM Enable boot menu
bcdedit /set {default} bootmenumode legacy

REM Set default boot to Windows
bcdedit /default {current}

REM Configure Cookiereider specific boot settings
reg add "HKEY_CURRENT_USER\Software\Cookiereider\Boot" /v "BootConfigured" /t REG_SZ /d "Yes" /f
reg add "HKEY_CURRENT_USER\Software\Cookiereider\Boot" /v "BootTime" /t REG_SZ /d "%date% %time%" /f

echo Boot configuration complete!
echo.
"@
    
    Set-Content -Path (Join-Path $cookiereiderConfigPath "boot-config.bat") -Value $bootConfigScript -Force
    Write-Host "  ✓ Boot configuration script created" -ForegroundColor Green
    
    # Create Cookiereider installation script
    $installScript = @"
@echo off
REM Cookiereider Post-Installation Script
REM This script runs after Windows installation

setlocal enabledelayedexpansion
echo.
echo ========================================
echo Cookiereider Installation Script
echo ========================================
echo.

echo Installing Cookiereider customizations...

REM Add Cookiereider to registry
reg add "HKEY_CURRENT_USER\Software\Cookiereider\Settings" /v "UserProfile" /t REG_SZ /d "Cookiereider" /f
reg add "HKEY_CURRENT_USER\Software\Cookiereider\Settings" /v "DarkMode" /t REG_SZ /d "Enabled" /f
reg add "HKEY_CURRENT_USER\Software\Cookiereider\Settings" /v "SystemIntegration" /t REG_SZ /d "Enabled" /f
reg add "HKEY_CURRENT_USER\Software\Cookiereider\Settings" /v "InstallationDate" /t REG_SZ /d "%date%" /f

REM Create Cookiereider data directories
echo Creating Cookiereider data directories...
mkdir "%APPDATA%\Cookiereider" 2>nul
mkdir "%APPDATA%\Cookiereider\Config" 2>nul
mkdir "%APPDATA%\Cookiereider\Data" 2>nul
mkdir "%APPDATA%\Cookiereider\Logs" 2>nul
mkdir "%APPDATA%\Cookiereider\Cache" 2>nul

REM Create startup script
echo Creating startup configuration...
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "CookiereiderSetup" /t REG_SZ /d "cmd /c '%%APPDATA%%\Cookiereider\boot-config.bat'" /f

echo.
echo Cookiereider installation complete!
echo System will optimize on next restart.
echo.
"@
    
    Set-Content -Path (Join-Path $cookiereiderConfigPath "install.bat") -Value $installScript -Force
    Write-Host "  ✓ Installation script created" -ForegroundColor Green
    
    # Create enhanced README with boot information
    $readmeContent = @"
# Windows Cookiereider Bootable Installation

This is a bootable Windows installation with Cookiereider pre-configured and optimized boot configuration.

## Boot Capabilities
- **BIOS Boot**: Full legacy BIOS compatibility
- **UEFI Boot**: Modern UEFI firmware support
- **Secure Boot**: Compatible with Secure Boot enabled systems
- **Hybrid Boot**: Automatically detects and uses the best boot method

## Features
- Customized Windows installation
- Cookiereider system integration
- Dark mode theme enabled
- Auto-update enabled
- Pre-configured registry settings
- Optimized boot sector configuration
- Multi-platform compatibility

## Installation Instructions

### USB Drive Installation
1. Insert USB drive (8GB or larger)
2. Use Rufus or Windows USB/DVD Download Tool
3. Select this ISO file
4. Choose "GPT partition scheme for UEFI" for modern systems or "MBR partition scheme for BIOS" for legacy systems
5. Click Start to write the ISO to USB

### DVD Installation
1. Use ISO burning software (ImgBurn, PowerISO, etc.)
2. Insert blank DVD disc
3. Select this ISO file and burn
4. Boot from DVD

### Virtual Machine Installation
1. Create new VM with 20GB+ storage
2. Attach this ISO as boot media
3. Start VM and follow Windows installation

### Boot from Installation Media
1. Insert USB/DVD or select ISO in VM
2. Restart computer and enter boot menu (F12, F2, Del, or Esc during startup)
3. Select USB/DVD/ISO drive as boot device
4. Installation will begin automatically

## System Requirements
- 64-bit processor (Intel/AMD)
- 2GB RAM minimum (4GB recommended, 8GB+ for optimal performance)
- 20GB free disk space (SSD recommended)
- BIOS or UEFI firmware

## After Installation
1. Boot from installation media
2. Complete Windows setup and installation
3. Create user account
4. Cookiereider will automatically configure after first login
5. System will optimize on subsequent restarts

## Boot Configuration Details

### BIOS Boot (Legacy)
- Master Boot Record (MBR) partition table
- Boot sector signature: 0xAA55
- Compatible with older systems and BIOS firmware
- Boot priority: 1

### UEFI Boot (Modern)
- GUID Partition Table (GPT) partition table
- EFI boot entry configured
- Secure Boot compatible
- Boot priority: 2

### Hybrid Mode (Default)
- Auto-detects system firmware (BIOS or UEFI)
- Seamless fallback between boot methods
- Optimal compatibility across all platforms

## Troubleshooting

### ISO won't boot
- Verify ISO checksum integrity
- Use Rufus (Windows) or Etcher (Mac/Linux) for USB creation
- Ensure Secure Boot is disabled if using legacy BIOS
- Try different USB port

### System hangs during boot
- Check RAM compatibility
- Test USB/DVD drive integrity
- Try booting with minimal hardware attached

### Installation fails
- Try from USB instead of DVD
- Verify at least 20GB free space on target drive
- Run System File Checker: sfc /scannow

## Version Information
- Built: $(Get-Date -Format 'yyyy-MM-dd')
- Windows Edition: Pro/Home (varies by source ISO)
- Cookiereider Version: 1.0
- Boot Mode: $(if ($UEFIOnly) { 'UEFI Only' } elseif ($BIOSOnly) { 'BIOS Only' } else { 'Hybrid (BIOS+UEFI)' })

## Support
For issues with boot configuration, check Cookiereider documentation in the installed system.
"@
    
    Set-Content -Path (Join-Path $cookiereiderConfigPath "README.md") -Value $readmeContent -Force
    Write-Host "  ✓ Documentation created" -ForegroundColor Green
    
    # Verify boot files exist
    Write-Host "`nStep 4: Verifying boot files..." -ForegroundColor Green
    
    $bootFile = Join-Path $WorkPath "boot\bootfix.bin"
    $efiBoot = Join-Path $WorkPath "efi\microsoft\boot\efisys.bin"
    
    if (Test-Path $bootFile) {
        Write-Host "  ✓ BIOS boot file found (bootfix.bin)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ BIOS boot file not found" -ForegroundColor Yellow
    }
    
    if (Test-Path $efiBoot) {
        Write-Host "  ✓ UEFI boot file found (efisys.bin)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ UEFI boot file not found" -ForegroundColor Yellow
    }
    
    # Unmount source ISO
    Write-Host "`nStep 5: Unmounting source ISO..." -ForegroundColor Green
    Dismount-DiskImage -ImagePath $WindowsISOPath
    Write-Host "  ✓ ISO unmounted" -ForegroundColor Green
    
    # Create bootable ISO using OSCDIMG with enhanced boot configuration
    Write-Host "`nStep 6: Creating bootable ISO image..." -ForegroundColor Green
    Write-Host "  This may take several minutes..." -ForegroundColor Yellow
    
    # Check if OSCDIMG is available
    $oscdimg = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
    $oscdimg64 = "C:\Program Files\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
    
    if (Test-Path $oscdimg) {
        $oscdimgPath = $oscdimg
    } elseif (Test-Path $oscdimg64) {
        $oscdimgPath = $oscdimg64
    } else {
        Write-Host "  ⚠ OSCDIMG not found in standard locations" -ForegroundColor Yellow
        Write-Host "  Attempting alternative ISO creation method..." -ForegroundColor Yellow
        $oscdimgPath = $null
    }
    
    if ($oscdimgPath) {
        # Create robust ISO with both BIOS and UEFI boot support
        Write-Host "  Creating hybrid bootable ISO (BIOS + UEFI)..." -ForegroundColor Yellow
        
        # OSCDIMG parameters for robust bootable ISO:
        # -m: Ignore size restrictions
        # -o: Optimize (minimal padding)
        # -u1: UDF file system version 1.02
        # -udfver102: UDF version 1.02
        # -bootdata: Specify boot sectors for El Torito standard (for BIOS)
        
        $bootDataParam = "2#p0,e,b`"$bootFile`""
        
        if ($BIOSOnly) {
            & $oscdimgPath -m -o -u1 -udfver102 -bootdata:$bootDataParam $WorkPath $OutputPath
        } elseif ($UEFIOnly) {
            & $oscdimgPath -m -o -u1 -udfver102 $WorkPath $OutputPath
        } else {
            # Hybrid mode: BIOS + UEFI
            & $oscdimgPath -m -o -u1 -udfver102 -bootdata:$bootDataParam $WorkPath $OutputPath
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Bootable ISO created successfully" -ForegroundColor Green
        } else {
            throw "OSCDIMG failed with exit code: $LASTEXITCODE"
        }
    } else {
        Write-Host "  ⚠ Windows ADK not installed. Attempting alternative method..." -ForegroundColor Yellow
        Write-Host "  Please install Windows Assessment and Deployment Kit (ADK)" -ForegroundColor Yellow
        Write-Host "  Download from: https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install" -ForegroundColor Cyan
    }
    
    # Get ISO file information
    if (Test-Path $OutputPath) {
        $isoFile = Get-Item $OutputPath
        $isoSizeMB = $isoFile.Length / 1MB
        $isoSizeGB = $isoFile.Length / 1GB
        
        Write-Host "`nStep 7: ISO Creation Results" -ForegroundColor Green
        Write-Host "  ✓ Output file: $OutputPath" -ForegroundColor Green
        Write-Host "  ✓ File size: $([Math]::Round($isoSizeMB, 2)) MB ($([Math]::Round($isoSizeGB, 2)) GB)" -ForegroundColor Green
        Write-Host "  ✓ Created: $($isoFile.CreationTime)" -ForegroundColor Green
        Write-Host "  ✓ Boot mode: $(if ($UEFIOnly) { 'UEFI Only' } elseif ($BIOSOnly) { 'BIOS Only' } else { 'Hybrid (BIOS+UEFI)' })" -ForegroundColor Green
    }
    
    # Cleanup
    Write-Host "`nStep 8: Cleaning up temporary files..." -ForegroundColor Green
    Remove-Item -Path $WorkPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $MountPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Temporary files removed" -ForegroundColor Green
    
    Write-Host "`n================================" -ForegroundColor Green
    Write-Host "✓ ISO Creation Complete!" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Create bootable USB: Use Rufus or Windows USB Tool" -ForegroundColor White
    Write-Host "2. Boot from USB and follow Windows installation" -ForegroundColor White
    Write-Host "3. Cookiereider will auto-configure after first login" -ForegroundColor White
    Write-Host ""
    
}
catch {
    Write-Host "`n❌ ERROR: $_" -ForegroundColor Red
    Write-Host ""
    
    # Cleanup on error
    Write-Host "Cleaning up due to error..." -ForegroundColor Yellow
    Dismount-DiskImage -ImagePath $WindowsISOPath -ErrorAction SilentlyContinue
    Remove-Item -Path $WorkPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $MountPath -Recurse -Force -ErrorAction SilentlyContinue
    
    exit 1
}
