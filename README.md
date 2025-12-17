# Desktop Background Manager

A PowerShell script to save, change, and restore your Windows desktop background settings.

## Features

- **Save** your current desktop background settings (wallpaper and solid color)
- **Set** the background to solid white
- **Restore** your original settings at any time

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

Displays the current wallpaper path and background color without making any changes.

### Save Current Settings

```powershell
.\BackgroundManager.ps1 -Save
```

Saves your current desktop background settings to a backup file. This includes:

- Current wallpaper image path
- Background color (RGB values)
- Wallpaper style and tile settings

The settings are saved to: `%USERPROFILE%\desktop_background_backup.json`

### Set Solid White Background

```powershell
.\BackgroundManager.ps1 -White
```

Changes your desktop background to a solid white color and removes any wallpaper image.

### Restore Saved Settings

```powershell
.\BackgroundManager.ps1 -Restore
```

Restores your desktop background to the previously saved settings.

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

- Windows Registry keys (`HKCU:\Control Panel\Colors` and `HKCU:\Control Panel\Desktop`) to read and write background settings
- The `SystemParametersInfo` Windows API to apply wallpaper changes immediately without requiring a restart or log off

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

## License

Free to use and modify.
