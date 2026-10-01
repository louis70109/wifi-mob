using System.ComponentModel;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net.Http;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;

namespace WiFiCat.Windows;

public partial class MainWindow : Window
{
    private static readonly MobOption[] MobOptions =
    {
        new("橘菇菇", "Mob_Orange_Mushroom.png"),
        new("蝸牛", "Mob_Snail.png"),
        new("豬", "Mob_Pig.png"),
        new("樹樁", "Mob_Stump.png"),
    };

    private readonly DispatcherTimer _signalTimer = new() { Interval = TimeSpan.FromSeconds(2) };
    private int _spriteRequest;
    private bool _pollingSignal;

    public MainWindow()
    {
        InitializeComponent();
        MobSelector.ItemsSource = MobOptions;
        _signalTimer.Tick += async (_, _) => await RefreshSignalAsync();
        Closed += (_, _) => _signalTimer.Stop();
    }

    private async void Window_Loaded(object sender, RoutedEventArgs e)
    {
        MobSelector.SelectedIndex = 0;
        await RefreshSignalAsync();
        _signalTimer.Start();
    }

    private void Window_Closed(object? sender, EventArgs e) => _signalTimer.Stop();

    private void DragHandle_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.LeftButton == MouseButtonState.Pressed)
            DragMove();
    }

    private void CloseButton_Click(object sender, RoutedEventArgs e) => Close();

    private async void MobSelector_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (MobSelector.SelectedItem is MobOption mob)
            await LoadMobImageAsync(mob);
    }

    private async Task LoadMobImageAsync(MobOption mob)
    {
        var request = ++_spriteRequest;
        MobImage.Source = null;
        MobHint.Text = "正在載入楓之谷原圖…";

        var image = await MobSpriteCache.LoadAsync(mob);
        if (request != _spriteRequest)
            return;

        MobImage.Source = image;
        MobHint.Text = image is null
            ? "圖片載入失敗，請確認網路連線。"
            : "原圖已快取，可離線顯示。";
    }

    private async Task RefreshSignalAsync()
    {
        if (_pollingSignal)
            return;

        _pollingSignal = true;
        try
        {
            var percent = await WindowsWifiSignal.ReadPercentAsync();
            if (percent is null)
            {
                SignalText.Text = "未連線 Wi-Fi";
                SignalBar.Value = 0;
                SignalBar.Foreground = new SolidColorBrush(Color.FromRgb(190, 94, 105));
                MobImage.Opacity = 0.58;
                return;
            }

            SignalBar.Value = percent.Value;
            var state = SignalAppearance.For(percent.Value);
            SignalText.Text = $"{state.Label} · {percent.Value}%";
            SignalBar.Foreground = new SolidColorBrush(state.Color);
            MobImage.Opacity = state.Opacity;
        }
        finally
        {
            _pollingSignal = false;
        }
    }
}

internal sealed record MobOption(string Name, string FileName)
{
    public Uri SpriteUrl => new($"https://media.maplestorywiki.net/yetidb/{FileName}");
}

internal static class MobSpriteCache
{
    private static readonly HttpClient Client = new() { Timeout = TimeSpan.FromSeconds(15) };
    private static readonly string CacheDirectory = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "WiFiCat",
        "mobs");

    public static async Task<BitmapSource?> LoadAsync(MobOption mob)
    {
        var cacheFile = Path.Combine(CacheDirectory, mob.FileName);
        try
        {
            Directory.CreateDirectory(CacheDirectory);
            var bytes = File.Exists(cacheFile)
                ? await File.ReadAllBytesAsync(cacheFile)
                : await Client.GetByteArrayAsync(mob.SpriteUrl);

            if (!File.Exists(cacheFile))
                await File.WriteAllBytesAsync(cacheFile, bytes);

            using var stream = new MemoryStream(bytes);
            var bitmap = new BitmapImage();
            bitmap.BeginInit();
            bitmap.CacheOption = BitmapCacheOption.OnLoad;
            bitmap.StreamSource = stream;
            bitmap.EndInit();
            bitmap.Freeze();
            return bitmap;
        }
        catch (Exception error) when (
            error is HttpRequestException or IOException or UnauthorizedAccessException or
            OperationCanceledException or FormatException or NotSupportedException)
        {
            return null;
        }
    }
}

internal static class WindowsWifiSignal
{
    private static readonly Regex LabeledSignal = new(
        @"^\s*(?:Signal|訊號|信號|信号|シグナル)\s*[:：]\s*(?<percent>\d{1,3})\s*%",
        RegexOptions.Multiline | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
    private static readonly Regex Percent = new(
        @"(?<percent>\d{1,3})\s*%",
        RegexOptions.CultureInvariant);

    public static async Task<int?> ReadPercentAsync()
    {
        try
        {
            using var process = new Process();
            process.StartInfo = new ProcessStartInfo
            {
                FileName = "netsh.exe",
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
            };
            process.StartInfo.ArgumentList.Add("wlan");
            process.StartInfo.ArgumentList.Add("show");
            process.StartInfo.ArgumentList.Add("interfaces");

            if (!process.Start())
                return null;

            var outputTask = process.StandardOutput.ReadToEndAsync();
            var errorTask = process.StandardError.ReadToEndAsync();
            await process.WaitForExitAsync();
            var output = await outputTask;
            _ = await errorTask;
            if (process.ExitCode != 0)
                return null;

            var match = LabeledSignal.Match(output);
            if (!match.Success)
                match = Percent.Match(output);
            return match.Success && int.TryParse(
                match.Groups["percent"].Value,
                NumberStyles.None,
                CultureInfo.InvariantCulture,
                out var value)
                ? Math.Clamp(value, 0, 100)
                : null;
        }
        catch (Exception error) when (
            error is Win32Exception or InvalidOperationException or IOException or TaskCanceledException)
        {
            return null;
        }
    }
}

internal static class SignalAppearance
{
    public static (string Label, Color Color, double Opacity) For(int percent) => percent switch
    {
        >= 80 => ("訊號極佳", Colors.LimeGreen, 1.0),
        >= 60 => ("訊號良好", Colors.Gold, 1.0),
        >= 40 => ("訊號普通", Colors.DarkOrange, 0.85),
        _ => ("訊號不穩", Colors.IndianRed, 0.58),
    };
}
