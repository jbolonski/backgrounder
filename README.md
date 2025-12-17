# Desktop Background Manager

A .NET console application to save, change, and restore your Windows desktop
background settings with **multi-monitor support**.

## Features

- **Save** your current desktop background settings for all monitors
- **Set** all monitors to solid white background
- **Restore** your original settings for all monitors
- **Multi-monitor support** using Windows IDesktopWallpaper COM interface
- **Per-monitor wallpaper tracking** - saves and restores each monitor individually

## Requirements

- Windows 10 or Windows 11
- .NET 8.0 Runtime (or build as self-contained)

## Installation

### Option 1: Build from Source

1. Clone or download this repository
2. Build the project:

   ```powershell
   cd BackgroundManager
   dotnet build -c Release
   ```

3. The executable will be in `bin\Release\net8.0-windows\`

### Option 2: Publish Self-Contained

```powershell
cd BackgroundManager
dotnet publish -c Release -r win-x64 --self-contained true -o publish
```

This creates a standalone executable that doesn't require .NET to be installed.

## Usage

### View Current Settings

```powershell
BackgroundManager.exe
# or
BackgroundManager.exe status
```

Displays the current background color, position, and per-monitor wallpaper settings.

### Save Current Settings

```powershell
BackgroundManager.exe save
```

Saves your current desktop background settings to a backup file. This includes:

- Wallpaper image path for each monitor
- Background color
- Wallpaper position (Fill, Fit, Stretch, etc.)
- Monitor device IDs for accurate restoration

The settings are saved to: `%USERPROFILE%\desktop_background_backup.json`

### Set Solid White Background

```powershell
BackgroundManager.exe white
```

Changes all monitors to a solid white background color and removes any
wallpaper images.

### Restore Saved Settings

```powershell
BackgroundManager.exe restore
```

Restores your desktop background to the previously saved settings for
all monitors.

> **Important:** You must run `save` before you can use `restore`.

### Get Help

```powershell
BackgroundManager.exe help
```

### Verbose Error Output

```powershell
BackgroundManager.exe white -v
```

The `-v` or `--verbose` flag shows detailed error information if something
goes wrong.

## Typical Workflow

1. **Before making changes**, save your current settings:

   ```powershell
   BackgroundManager.exe save
   ```

2. **Set to white** when needed (e.g., for screen recording, presentations):

   ```powershell
   BackgroundManager.exe white
   ```

3. **Restore** your original background when done:

   ```powershell
   BackgroundManager.exe restore
   ```

## How It Works

The application uses the **IDesktopWallpaper COM interface** which provides:

- `GetMonitorDevicePathCount()` - Get number of monitors
- `GetMonitorDevicePathAt()` - Get unique ID for each monitor
- `GetWallpaper()` / `SetWallpaper()` - Per-monitor wallpaper control
- `GetBackgroundColor()` / `SetBackgroundColor()` - Solid color background
- `GetPosition()` / `SetPosition()` - Wallpaper positioning mode

This is the same API that Windows Settings uses for desktop personalization.

## Multi-Monitor Support

The application automatically detects all connected monitors and:

- Saves individual wallpaper paths for each monitor using device IDs
- Restores the correct wallpaper to each specific monitor
- Sets solid white on all monitors simultaneously
- Tracks monitor positions for identification

## Files

| File | Description |
|------|-------------|
| `BackgroundManager/` | .NET 8 console application source |
| `%USERPROFILE%\desktop_background_backup.json` | Backup file created when using `save` |

## Project Structure

```text
BackgroundManager/
├── BackgroundManager.csproj    # Project file
├── Program.cs                  # Entry point and command handling
├── IDesktopWallpaper.cs        # COM interface definitions
├── WallpaperManager.cs         # Core wallpaper operations
└── WallpaperSettings.cs        # Settings model for JSON serialization
```

## Troubleshooting

### Restore says "No saved settings found"

You need to run `save` first to create a backup before you can restore.

### Background doesn't change immediately

The IDesktopWallpaper COM interface should update immediately. If changes
don't appear:

- Minimize all windows to view the desktop
- Right-click desktop → Personalize → Background to verify the change

### Multi-monitor not working correctly

If per-monitor wallpapers aren't being saved/restored correctly:

- Make sure all monitors are connected when saving settings
- Monitor device IDs are hardware-specific; if you change monitors,
  re-save your settings
- Check the verbose output with `-v` flag for detailed error information

### COM Exception errors

If you see COM exceptions:

- Ensure you're running on Windows 10 or later
- Try running as Administrator
- Use the `-v` flag to see the full error details
