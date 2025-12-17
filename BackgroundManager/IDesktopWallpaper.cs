using System.Runtime.InteropServices;

namespace BackgroundManager;

/// <summary>
/// Desktop wallpaper position options
/// </summary>
public enum DesktopWallpaperPosition
{
    Center = 0,
    Tile = 1,
    Stretch = 2,
    Fit = 3,
    Fill = 4,
    Span = 5
}

/// <summary>
/// IDesktopWallpaper COM interface for per-monitor wallpaper control
/// </summary>
[ComImport]
[Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IDesktopWallpaper
{
    void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] string wallpaper);
    
    [return: MarshalAs(UnmanagedType.LPWStr)]
    string GetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID);
    
    [return: MarshalAs(UnmanagedType.LPWStr)]
    string GetMonitorDevicePathAt(uint monitorIndex);
    
    uint GetMonitorDevicePathCount();
    
    void GetMonitorRECT([MarshalAs(UnmanagedType.LPWStr)] string monitorID, out RECT displayRect);
    
    void SetBackgroundColor(uint color);
    
    uint GetBackgroundColor();
    
    void SetPosition(DesktopWallpaperPosition position);
    
    DesktopWallpaperPosition GetPosition();
    
    void SetSlideshow(IntPtr items);
    
    IntPtr GetSlideshow();
    
    void SetSlideshowOptions(uint options, uint slideshowTick);
    
    void GetSlideshowOptions(out uint options, out uint slideshowTick);
    
    void AdvanceSlideshow([MarshalAs(UnmanagedType.LPWStr)] string monitorID, uint direction);
    
    uint GetStatus();
    
    void Enable([MarshalAs(UnmanagedType.Bool)] bool enable);
}

[StructLayout(LayoutKind.Sequential)]
public struct RECT
{
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
    
    public int Width => Right - Left;
    public int Height => Bottom - Top;
}

/// <summary>
/// DesktopWallpaper coclass
/// </summary>
[ComImport]
[Guid("C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD")]
public class DesktopWallpaperClass
{
}
