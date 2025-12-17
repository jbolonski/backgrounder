using System.Text.Json;

namespace BackgroundManager;

/// <summary>
/// Represents saved wallpaper settings for restoration
/// </summary>
public class WallpaperSettings
{
    public uint BackgroundColor { get; set; }
    public DesktopWallpaperPosition Position { get; set; }
    public List<MonitorWallpaper> Monitors { get; set; } = new();
    public DateTime SavedAt { get; set; }
    
    private static string SettingsFilePath => 
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "desktop_background_backup.json");
    
    public void Save()
    {
        var options = new JsonSerializerOptions { WriteIndented = true };
        var json = JsonSerializer.Serialize(this, options);
        File.WriteAllText(SettingsFilePath, json);
    }
    
    public static WallpaperSettings? Load()
    {
        if (!File.Exists(SettingsFilePath))
            return null;
            
        var json = File.ReadAllText(SettingsFilePath);
        return JsonSerializer.Deserialize<WallpaperSettings>(json);
    }
    
    public static string GetSettingsPath() => SettingsFilePath;
}

/// <summary>
/// Represents wallpaper settings for a single monitor
/// </summary>
public class MonitorWallpaper
{
    public int Index { get; set; }
    public string MonitorId { get; set; } = string.Empty;
    public string WallpaperPath { get; set; } = string.Empty;
    public int Left { get; set; }
    public int Top { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }
    public bool IsPrimary { get; set; }
}
