# BackgroundManager.ps1
# Desktop Background Manager - Save, Set White, and Restore (Multi-Monitor Support)
#
# Usage: 
#   .\BackgroundManager.ps1 -Save       # Save current settings for all monitors
#   .\BackgroundManager.ps1 -White      # Set all monitors to solid white
#   .\BackgroundManager.ps1 -Restore    # Restore saved settings for all monitors
#   .\BackgroundManager.ps1             # Show current settings

param(
    [switch]$Save,
    [switch]$White,
    [switch]$Restore
)

$settingsFile = "$env:USERPROFILE\desktop_background_backup.json"

# Add required Windows API
$typeAdded = $false
try {
    [DesktopWallpaperAPI] | Out-Null
    $typeAdded = $true
} catch {
    # Type not loaded yet
}

if (-not $typeAdded) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class DesktopWallpaperAPI {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, StringBuilder lpvParam, int fuWinIni);
    
    public const int SPI_SETDESKWALLPAPER = 0x0014;
    public const int SPI_GETDESKWALLPAPER = 0x0073;
    public const int SPIF_UPDATEINIFILE = 0x01;
    public const int SPIF_SENDCHANGE = 0x02;
    
    public static string GetCurrentWallpaper() {
        StringBuilder sb = new StringBuilder(260);
        SystemParametersInfo(SPI_GETDESKWALLPAPER, 260, sb, 0);
        return sb.ToString();
    }
    
    public static void SetWallpaper(string path) {
        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    }
}
"@
}

function Get-MonitorWallpapers {
    # Get per-monitor wallpapers from Windows registry (Windows 10/11)
    $monitors = @()
    
    # Get current primary wallpaper
    $primaryWallpaper = [DesktopWallpaperAPI]::GetCurrentWallpaper()
    
    # Get screen info using .NET reflection to load assembly properly
    try {
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        $screens = [System.Windows.Forms.Screen]::AllScreens
        
        $index = 0
        foreach ($screen in $screens) {
            $monitors += @{
                Index = $index
                DeviceName = $screen.DeviceName
                Primary = $screen.Primary
                Bounds = @{
                    X = $screen.Bounds.X
                    Y = $screen.Bounds.Y
                    Width = $screen.Bounds.Width
                    Height = $screen.Bounds.Height
                }
                Wallpaper = $primaryWallpaper
            }
            $index++
        }
    }
    catch {
        # Fallback: use WMI to get monitor info
        $wmiMonitors = Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue
        $index = 0
        foreach ($monitor in $wmiMonitors) {
            $monitors += @{
                Index = $index
                DeviceName = $monitor.Name
                Primary = ($index -eq 0)
                Bounds = @{
                    X = 0
                    Y = 0
                    Width = $monitor.CurrentHorizontalResolution
                    Height = $monitor.CurrentVerticalResolution
                }
                Wallpaper = $primaryWallpaper
            }
            $index++
        }
    }
    
    # If still no monitors found, add a default
    if ($monitors.Count -eq 0) {
        $monitors += @{
            Index = 0
            DeviceName = "Primary"
            Primary = $true
            Bounds = @{ X = 0; Y = 0; Width = 1920; Height = 1080 }
            Wallpaper = $primaryWallpaper
        }
    }
    
    return $monitors
}

function Get-CurrentSettings {
    # Get background color (system-wide)
    $bgColor = (Get-ItemProperty -Path 'HKCU:\Control Panel\Colors' -Name Background).Background
    
    # Get wallpaper style
    $desktopProps = Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -ErrorAction SilentlyContinue
    $style = $desktopProps.WallpaperStyle
    $tile = $desktopProps.TileWallpaper
    $wallpaper = $desktopProps.Wallpaper
    
    # Get current wallpaper via API
    $currentWallpaper = [DesktopWallpaperAPI]::GetCurrentWallpaper()
    
    # Get monitor info
    $monitors = Get-MonitorWallpapers
    
    $settings = @{
        BackgroundColor = $bgColor
        WallpaperStyle = $style
        TileWallpaper = $tile
        Wallpaper = $currentWallpaper
        WallpaperRegistry = $wallpaper
        MonitorCount = $monitors.Count
        Monitors = $monitors
    }
    
    return $settings
}

function Save-Settings {
    $settings = Get-CurrentSettings
    $settings | ConvertTo-Json -Depth 5 | Out-File -FilePath $settingsFile -Encoding UTF8
    
    Write-Host "Settings saved to: $settingsFile" -ForegroundColor Green
    Write-Host "  Wallpaper: $($settings.Wallpaper)" -ForegroundColor Cyan
    Write-Host "  Background Color (RGB): $($settings.BackgroundColor)" -ForegroundColor Cyan
    Write-Host "  Wallpaper Style: $($settings.WallpaperStyle)" -ForegroundColor Cyan
    Write-Host "  Monitors detected: $($settings.MonitorCount)" -ForegroundColor Cyan
    
    foreach ($monitor in $settings.Monitors) {
        $primary = if ($monitor.Primary) { " (Primary)" } else { "" }
        Write-Host "    Monitor $($monitor.Index)$primary : $($monitor.DeviceName) - $($monitor.Bounds.Width)x$($monitor.Bounds.Height)" -ForegroundColor Gray
    }
}

function Set-SolidWhite {
    # Get monitor count for display
    $monitorCount = 1
    try {
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        $monitorCount = [System.Windows.Forms.Screen]::AllScreens.Count
    }
    catch {
        $wmiMonitors = Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue
        $monitorCount = @($wmiMonitors).Count
        if ($monitorCount -eq 0) { $monitorCount = 1 }
    }
    
    # Set background color to white in registry (255 255 255)
    Set-ItemProperty -Path 'HKCU:\Control Panel\Colors' -Name Background -Value "255 255 255"
    
    # Set wallpaper style to centered (will show solid color with no image)
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value "0"
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value "0"
    
    # Remove wallpaper (set to empty string for solid color)
    [DesktopWallpaperAPI]::SetWallpaper("")
    
    Write-Host "Background set to solid white on $monitorCount monitor(s)!" -ForegroundColor Green
}

function Restore-Settings {
    if (-not (Test-Path $settingsFile)) {
        Write-Host "No saved settings found at: $settingsFile" -ForegroundColor Red
        Write-Host "Run with -Save first to backup your settings." -ForegroundColor Yellow
        return
    }
    
    $settings = Get-Content -Path $settingsFile -Raw | ConvertFrom-Json
    
    # Restore background color in registry
    Set-ItemProperty -Path 'HKCU:\Control Panel\Colors' -Name Background -Value $settings.BackgroundColor
    
    # Restore wallpaper style
    if ($null -ne $settings.WallpaperStyle) {
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value $settings.WallpaperStyle
    }
    if ($null -ne $settings.TileWallpaper) {
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value $settings.TileWallpaper
    }
    
    # Restore wallpaper
    $wallpaperToRestore = $settings.Wallpaper
    if ([string]::IsNullOrEmpty($wallpaperToRestore)) {
        $wallpaperToRestore = $settings.WallpaperRegistry
    }
    
    [DesktopWallpaperAPI]::SetWallpaper($wallpaperToRestore)
    
    Write-Host "Settings restored!" -ForegroundColor Green
    Write-Host "  Wallpaper: $wallpaperToRestore" -ForegroundColor Cyan
    Write-Host "  Background Color (RGB): $($settings.BackgroundColor)" -ForegroundColor Cyan
    Write-Host "  Monitors in backup: $($settings.MonitorCount)" -ForegroundColor Cyan
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
    Write-Host "Desktop Background Manager (Multi-Monitor)" -ForegroundColor Yellow
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  .\BackgroundManager.ps1 -Save     # Save current background settings"
    Write-Host "  .\BackgroundManager.ps1 -White    # Set all monitors to solid white"
    Write-Host "  .\BackgroundManager.ps1 -Restore  # Restore saved settings"
    Write-Host ""
    Write-Host "Current Settings:" -ForegroundColor Cyan
    $current = Get-CurrentSettings
    Write-Host "  Wallpaper: $($current.Wallpaper)"
    Write-Host "  Background Color (RGB): $($current.BackgroundColor)"
    Write-Host "  Wallpaper Style: $($current.WallpaperStyle)"
    Write-Host "  Monitors: $($current.MonitorCount)" -ForegroundColor Cyan
    foreach ($monitor in $current.Monitors) {
        $primary = if ($monitor.Primary) { " (Primary)" } else { "" }
        Write-Host "    Monitor $($monitor.Index)$primary : $($monitor.DeviceName) - $($monitor.Bounds.Width)x$($monitor.Bounds.Height)" -ForegroundColor Gray
    }
}
