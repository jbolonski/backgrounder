using System.Windows.Forms;

namespace BackgroundManager;

/// <summary>
/// Manages desktop wallpaper operations using the IDesktopWallpaper COM interface
/// </summary>
public class WallpaperManager : IDisposable
{
    private readonly IDesktopWallpaper _wallpaper;
    private bool _disposed;

    public WallpaperManager()
    {
        _wallpaper = (IDesktopWallpaper)new DesktopWallpaperClass();
    }

    /// <summary>
    /// Gets information about all monitors
    /// </summary>
    public List<MonitorWallpaper> GetMonitorInfo()
    {
        var monitors = new List<MonitorWallpaper>();
        var count = _wallpaper.GetMonitorDevicePathCount();
        var screens = Screen.AllScreens;

        for (uint i = 0; i < count; i++)
        {
            var monitorId = _wallpaper.GetMonitorDevicePathAt(i);
            
            string wallpaperPath = "";
            try
            {
                wallpaperPath = _wallpaper.GetWallpaper(monitorId);
            }
            catch
            {
                // Wallpaper may not be set
            }
            
            // Try to get rect from COM, fall back to Screen info
            int left = 0, top = 0, width = 1920, height = 1080;
            bool isPrimary = (i == 0);
            
            try
            {
                _wallpaper.GetMonitorRECT(monitorId, out RECT rect);
                left = rect.Left;
                top = rect.Top;
                width = rect.Width;
                height = rect.Height;
                
                // Match with Screen info for primary status
                foreach (var screen in screens)
                {
                    if (screen.Bounds.X == left && screen.Bounds.Y == top)
                    {
                        isPrimary = screen.Primary;
                        break;
                    }
                }
            }
            catch
            {
                // GetMonitorRECT failed, try to match by index with Screen array
                if (i < screens.Length)
                {
                    var screen = screens[i];
                    left = screen.Bounds.X;
                    top = screen.Bounds.Y;
                    width = screen.Bounds.Width;
                    height = screen.Bounds.Height;
                    isPrimary = screen.Primary;
                }
            }

            monitors.Add(new MonitorWallpaper
            {
                Index = (int)i,
                MonitorId = monitorId,
                WallpaperPath = wallpaperPath,
                Left = left,
                Top = top,
                Width = width,
                Height = height,
                IsPrimary = isPrimary
            });
        }

        return monitors;
    }

    /// <summary>
    /// Gets current wallpaper settings for all monitors
    /// </summary>
    public WallpaperSettings GetCurrentSettings()
    {
        return new WallpaperSettings
        {
            BackgroundColor = _wallpaper.GetBackgroundColor(),
            Position = _wallpaper.GetPosition(),
            Monitors = GetMonitorInfo(),
            SavedAt = DateTime.Now
        };
    }

    /// <summary>
    /// Saves current settings to file
    /// </summary>
    public void SaveSettings()
    {
        var settings = GetCurrentSettings();
        settings.Save();
        
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine($"Settings saved to: {WallpaperSettings.GetSettingsPath()}");
        Console.ResetColor();
        
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine($"  Background Color: #{settings.BackgroundColor:X6}");
        Console.WriteLine($"  Position: {settings.Position}");
        Console.WriteLine($"  Monitors: {settings.Monitors.Count}");
        Console.ResetColor();
        
        foreach (var monitor in settings.Monitors)
        {
            var primary = monitor.IsPrimary ? " (Primary)" : "";
            Console.ForegroundColor = ConsoleColor.Gray;
            Console.WriteLine($"    Monitor {monitor.Index}{primary}: {monitor.Width}x{monitor.Height} at ({monitor.Left},{monitor.Top})");
            Console.WriteLine($"      Wallpaper: {(string.IsNullOrEmpty(monitor.WallpaperPath) ? "(none)" : monitor.WallpaperPath)}");
            Console.ResetColor();
        }
    }

    /// <summary>
    /// Sets all monitors to solid white background
    /// </summary>
    public void SetSolidWhite()
    {
        var monitors = GetMonitorInfo();
        
        // Set background color to white (0x00FFFFFF in BGR format)
        // Note: Windows uses BGR format, so white is 0x00FFFFFF
        _wallpaper.SetBackgroundColor(0x00FFFFFF);
        
        // Remove wallpaper from each monitor
        foreach (var monitor in monitors)
        {
            _wallpaper.SetWallpaper(monitor.MonitorId, "");
            Console.ForegroundColor = ConsoleColor.Gray;
            Console.WriteLine($"  Cleared wallpaper on Monitor {monitor.Index}");
            Console.ResetColor();
        }
        
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine($"\nBackground set to solid white on {monitors.Count} monitor(s)!");
        Console.ResetColor();
    }

    /// <summary>
    /// Restores settings from saved file
    /// </summary>
    public void RestoreSettings()
    {
        var settings = WallpaperSettings.Load();
        
        if (settings == null)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine($"No saved settings found at: {WallpaperSettings.GetSettingsPath()}");
            Console.ResetColor();
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("Run with 'save' first to backup your settings.");
            Console.ResetColor();
            return;
        }
        
        // Restore background color
        _wallpaper.SetBackgroundColor(settings.BackgroundColor);
        
        // Restore position
        _wallpaper.SetPosition(settings.Position);
        
        // Restore per-monitor wallpapers
        int restoredCount = 0;
        foreach (var monitor in settings.Monitors)
        {
            try
            {
                _wallpaper.SetWallpaper(monitor.MonitorId, monitor.WallpaperPath);
                Console.ForegroundColor = ConsoleColor.Gray;
                var wpName = string.IsNullOrEmpty(monitor.WallpaperPath) ? "(solid color)" : Path.GetFileName(monitor.WallpaperPath);
                Console.WriteLine($"  Restored Monitor {monitor.Index}: {wpName}");
                Console.ResetColor();
                restoredCount++;
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine($"  Warning: Could not restore Monitor {monitor.Index}: {ex.Message}");
                Console.ResetColor();
            }
        }
        
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine($"\nSettings restored for {restoredCount} monitor(s)!");
        Console.ResetColor();
        
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine($"  Background Color: #{settings.BackgroundColor:X6}");
        Console.WriteLine($"  Position: {settings.Position}");
        Console.WriteLine($"  Saved at: {settings.SavedAt}");
        Console.ResetColor();
    }

    /// <summary>
    /// Displays current settings without saving
    /// </summary>
    public void ShowCurrentSettings()
    {
        var settings = GetCurrentSettings();
        
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("Current Settings:");
        Console.ResetColor();
        Console.WriteLine($"  Background Color: #{settings.BackgroundColor:X6}");
        Console.WriteLine($"  Position: {settings.Position}");
        Console.WriteLine($"  Monitors: {settings.Monitors.Count}");
        
        foreach (var monitor in settings.Monitors)
        {
            var primary = monitor.IsPrimary ? " (Primary)" : "";
            Console.ForegroundColor = ConsoleColor.Gray;
            Console.WriteLine($"    Monitor {monitor.Index}{primary}: {monitor.Width}x{monitor.Height} at ({monitor.Left},{monitor.Top})");
            Console.WriteLine($"      Wallpaper: {(string.IsNullOrEmpty(monitor.WallpaperPath) ? "(none/solid color)" : monitor.WallpaperPath)}");
            Console.ResetColor();
        }
    }

    public void Dispose()
    {
        if (!_disposed)
        {
            if (_wallpaper != null)
            {
                System.Runtime.InteropServices.Marshal.ReleaseComObject(_wallpaper);
            }
            _disposed = true;
        }
    }
}
