using BackgroundManager;

Console.ForegroundColor = ConsoleColor.Yellow;
Console.WriteLine("Desktop Background Manager (Multi-Monitor)");
Console.WriteLine("===========================================");
Console.ResetColor();
Console.WriteLine();

if (args.Length == 0)
{
    ShowUsage();
    Console.WriteLine();
    
    using var manager = new WallpaperManager();
    manager.ShowCurrentSettings();
    return 0;
}

var command = args[0].ToLowerInvariant().TrimStart('-', '/');

try
{
    using var manager = new WallpaperManager();
    
    switch (command)
    {
        case "save":
            manager.SaveSettings();
            break;
            
        case "white":
            manager.SetSolidWhite();
            break;
            
        case "restore":
            manager.RestoreSettings();
            break;
            
        case "status":
        case "show":
            manager.ShowCurrentSettings();
            break;
            
        case "help":
        case "?":
            ShowUsage();
            break;
            
        default:
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine($"Unknown command: {args[0]}");
            Console.ResetColor();
            ShowUsage();
            return 1;
    }
    
    return 0;
}
catch (Exception ex)
{
    Console.ForegroundColor = ConsoleColor.Red;
    Console.WriteLine($"Error: {ex.Message}");
    Console.ResetColor();
    
    if (args.Contains("--verbose") || args.Contains("-v"))
    {
        Console.WriteLine();
        Console.WriteLine(ex.ToString());
    }
    
    return 1;
}

void ShowUsage()
{
    Console.ForegroundColor = ConsoleColor.Cyan;
    Console.WriteLine("Usage:");
    Console.ResetColor();
    Console.WriteLine("  BackgroundManager save      Save current background settings");
    Console.WriteLine("  BackgroundManager white     Set all monitors to solid white");
    Console.WriteLine("  BackgroundManager restore   Restore saved settings");
    Console.WriteLine("  BackgroundManager status    Show current settings");
    Console.WriteLine("  BackgroundManager help      Show this help");
    Console.WriteLine();
    Console.WriteLine("Options:");
    Console.WriteLine("  -v, --verbose    Show detailed error information");
}
