# BackgroundManager.ps1
# Desktop Background Manager - Save, Set White, and Restore
#
# Usage: 
#   .\BackgroundManager.ps1 -Save       # Save current settings
#   .\BackgroundManager.ps1 -White      # Set to solid white
#   .\BackgroundManager.ps1 -Restore    # Restore saved settings
#   .\BackgroundManager.ps1             # Show current settings

param(
    [switch]$Save,
    [switch]$White,
    [switch]$Restore
)

$settingsFile = "$env:USERPROFILE\desktop_background_backup.json"

# Add required Windows API
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class DesktopBackground {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, System.Text.StringBuilder lpvParam, int fuWinIni);
    
    public const int SPI_SETDESKWALLPAPER = 0x0014;
    public const int SPI_GETDESKWALLPAPER = 0x0073;
    public const int SPIF_UPDATEINIFILE = 0x01;
    public const int SPIF_SENDCHANGE = 0x02;
}
"@ -ErrorAction SilentlyContinue

function Get-CurrentSettings {
    # Get wallpaper path
    $sb = New-Object System.Text.StringBuilder 260
    [DesktopBackground]::SystemParametersInfo([DesktopBackground]::SPI_GETDESKWALLPAPER, 260, $sb, 0) | Out-Null
    $wallpaper = $sb.ToString()
    
    # Get background color
    $bgColor = (Get-ItemProperty -Path 'HKCU:\Control Panel\Colors' -Name Background).Background
    
    # Get wallpaper style
    $style = Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -ErrorAction SilentlyContinue
    $tile = Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -ErrorAction SilentlyContinue
    
    return @{
        Wallpaper = $wallpaper
        BackgroundColor = $bgColor
        WallpaperStyle = $style.WallpaperStyle
        TileWallpaper = $tile.TileWallpaper
    }
}

function Save-Settings {
    $settings = Get-CurrentSettings
    $settings | ConvertTo-Json | Out-File -FilePath $settingsFile -Encoding UTF8
    Write-Host "Settings saved to: $settingsFile" -ForegroundColor Green
    Write-Host "  Wallpaper: $($settings.Wallpaper)" -ForegroundColor Cyan
    Write-Host "  Background Color (RGB): $($settings.BackgroundColor)" -ForegroundColor Cyan
}

function Set-SolidWhite {
    # Set background color to white (255 255 255)
    Set-ItemProperty -Path 'HKCU:\Control Panel\Colors' -Name Background -Value "255 255 255"
    
    # Remove wallpaper (set to empty string for solid color)
    [DesktopBackground]::SystemParametersInfo(
        [DesktopBackground]::SPI_SETDESKWALLPAPER, 
        0, 
        "", 
        [DesktopBackground]::SPIF_UPDATEINIFILE -bor [DesktopBackground]::SPIF_SENDCHANGE
    ) | Out-Null
    
    Write-Host "Background set to solid white!" -ForegroundColor Green
}

function Restore-Settings {
    if (-not (Test-Path $settingsFile)) {
        Write-Host "No saved settings found at: $settingsFile" -ForegroundColor Red
        Write-Host "Run with -Save first to backup your settings." -ForegroundColor Yellow
        return
    }
    
    $settings = Get-Content -Path $settingsFile -Raw | ConvertFrom-Json
    
    # Restore background color
    Set-ItemProperty -Path 'HKCU:\Control Panel\Colors' -Name Background -Value $settings.BackgroundColor
    
    # Restore wallpaper style
    if ($settings.WallpaperStyle) {
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value $settings.WallpaperStyle
    }
    if ($settings.TileWallpaper) {
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value $settings.TileWallpaper
    }
    
    # Restore wallpaper
    [DesktopBackground]::SystemParametersInfo(
        [DesktopBackground]::SPI_SETDESKWALLPAPER, 
        0, 
        $settings.Wallpaper, 
        [DesktopBackground]::SPIF_UPDATEINIFILE -bor [DesktopBackground]::SPIF_SENDCHANGE
    ) | Out-Null
    
    Write-Host "Settings restored!" -ForegroundColor Green
    Write-Host "  Wallpaper: $($settings.Wallpaper)" -ForegroundColor Cyan
    Write-Host "  Background Color (RGB): $($settings.BackgroundColor)" -ForegroundColor Cyan
}

# Main execution
if ($Save) {
    Save-Settings
}
elseif ($White) {
    Set-SolidWhite
}
elseif ($Restore) {
    Restore-Settings
}
else {
    Write-Host "Desktop Background Manager" -ForegroundColor Yellow
    Write-Host "==========================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  .\BackgroundManager.ps1 -Save     # Save current background settings"
    Write-Host "  .\BackgroundManager.ps1 -White    # Set background to solid white"
    Write-Host "  .\BackgroundManager.ps1 -Restore  # Restore saved settings"
    Write-Host ""
    Write-Host "Current Settings:" -ForegroundColor Cyan
    $current = Get-CurrentSettings
    Write-Host "  Wallpaper: $($current.Wallpaper)"
    Write-Host "  Background Color (RGB): $($current.BackgroundColor)"
}
