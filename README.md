# Desktop Background Manager

A PowerShell script to save, change, and restore your Windows desktop background settings with **multi-monitor support**.

## Features

- **Save** your current desktop background settings for all monitors
- **Set** all monitors to solid white background
- **Restore** your original settings for all monitors
- **Multi-monitor support** using Windows IDesktopWallpaper COM interface
- **Automatic fallback** to single-monitor mode on older systems

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or later

## Installation

1. Download or copy `BackgroundManager.ps1` to a folder of your choice
2. Open PowerShell and navigate to that folder

> **Note:** You may need to adjust your execution policy to run the script:
>
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

## Usage

### View Current Settings

```powershell
.\BackgroundManager.ps1
```

Displays the current wallpaper path, background color, and per-monitor wallpaper settings.

### Save Current Settings

```powershell
.\BackgroundManager.ps1 -Save
```

Saves your current desktop background settings to a backup file. This includes:

- Wallpaper image path for each monitor
- Background color (RGB values)
- Wallpaper style, position, and tile settings

The settings are saved to: `%USERPROFILE%\desktop_background_backup.json`

### Set Solid White Background

```powershell
.\BackgroundManager.ps1 -White
```

Changes all monitors to a solid white background color and removes any wallpaper images.

### Restore Saved Settings

```powershell
.\BackgroundManager.ps1 -Restore
```

Restores your desktop background to the previously saved settings for all monitors.

> **Important:** You must run `-Save` before you can use `-Restore`.

## Typical Workflow

1. **Before making changes**, save your current settings:

   ```powershell
   .\BackgroundManager.ps1 -Save
   ```

2. **Set to white** when needed (e.g., for screen recording, presentations):

   ```powershell
   .\BackgroundManager.ps1 -White
   ```

3. **Restore** your original background when done:

   ```powershell
   .\BackgroundManager.ps1 -Restore
   ```

## How It Works

The script uses:

- **IDesktopWallpaper COM interface** for per-monitor wallpaper control (Windows 8+)
- Windows Registry keys (`HKCU:\Control Panel\Colors` and `HKCU:\Control Panel\Desktop`) for background settings
- Automatic fallback to `SystemParametersInfo` API for single-monitor systems

## Multi-Monitor Support

The script automatically detects all connected monitors and:

- Saves individual wallpaper paths for each monitor
- Restores the correct wallpaper to each specific monitor
- Sets solid white on all monitors simultaneously

If the IDesktopWallpaper interface is not available (older Windows versions), the script falls back to single-monitor mode.

## Files

| File | Description |
|------|-------------|
| `BackgroundManager.ps1` | The main script |
| `%USERPROFILE%\desktop_background_backup.json` | Backup file created when using `-Save` |

## Troubleshooting

### Script won't run

Make sure your execution policy allows running scripts:

```powershell
Get-ExecutionPolicy -Scope CurrentUser
```

If it returns `Restricted`, run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Restore says "No saved settings found"

You need to run the script with `-Save` first to create a backup before you can restore.

### Background doesn't change immediately

The script uses Windows API calls to refresh the desktop immediately. If changes don't appear, try:

- Minimizing all windows to view the desktop
- Right-click desktop > Personalize > Background to verify the change

### Multi-monitor not working correctly

If per-monitor wallpapers aren't being saved/restored correctly:

- Make sure all monitors are connected when saving settings
- The script stores monitor IDs - if you change monitor configurations, you may need to re-save
- Try running PowerShell as Administrator

## License

Free to use and modify.
