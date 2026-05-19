using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading.Tasks;
using System.Windows;

namespace JiaRemoteWin
{
    public partial class App : Application
    {
        private MainWindow _mainWindow;
        private DebugLogListener _logListener;
        private DebugLogWindow _logWindow;
        private readonly List<string> _logBuffer = new List<string>();
        private const int MaxBufferLines = 5000;

        public static DebugLogListener SharedLogListener { get; private set; }

        private void Application_Startup(object sender, StartupEventArgs e)
        {
            try
            {
                _logListener = new DebugLogListener();
                _logListener.LogReceived += OnLogLine;
                Trace.Listeners.Add(_logListener);
                SharedLogListener = _logListener;

                _mainWindow = new MainWindow();
                _mainWindow.ConnectRequested += OnConnectRequested;
                _mainWindow.DisconnectRequested += OnDisconnectRequested;
                _mainWindow.ScanRequested += OnScanRequested;
                _mainWindow.SettingsRequested += OnSettingsRequested;
                _mainWindow.ShowDebugLog += () => ShowDebugLog();

                _mainWindow.Show();

                Debug.WriteLine("[JiaRemote] Windows 主控端已启动，窗口已显示");
            }
            catch (Exception ex)
            {
                string err = $"启动失败: {ex.Message}\n{ex.StackTrace}\n\nInner: {ex.InnerException?.Message}";
                Debug.WriteLine($"[JiaRemote] {err}");
                System.Console.Error.WriteLine(err);
                System.IO.File.WriteAllText(@"C:\Users\Administrator\Desktop\jia_error.log", err);
                MessageBox.Show(err, "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                Shutdown(1);
            }
        }

        private void OnLogLine(string line)
        {
            lock (_logBuffer)
            {
                _logBuffer.Add(line);
                while (_logBuffer.Count > MaxBufferLines)
                    _logBuffer.RemoveAt(0);
            }

            if (_logWindow != null && _logWindow.IsVisible)
            {
                _logWindow.AppendLine(line);
            }
        }

        public void ShowDebugLog()
        {
            if (_logWindow == null || !_logWindow.IsLoaded)
            {
                _logWindow = new DebugLogWindow
                {
                    Owner = _mainWindow,
                    WindowStartupLocation = WindowStartupLocation.CenterOwner
                };
            }

            lock (_logBuffer)
            {
                foreach (var line in _logBuffer)
                {
                    _logWindow.AppendLine(line);
                }
            }

            _logWindow.Show();
            _logWindow.Activate();
        }

        private async void OnConnectRequested(string host, int port)
        {
            await _mainWindow.ConnectAsync(host, port);
        }

        private void OnDisconnectRequested()
        {
            _mainWindow.Disconnect();
        }

        private void OnScanRequested(int port)
        {
            _ = DoScanAsync(port);
        }

        private async Task DoScanAsync(int port)
        {
            var scanner = new ScanHelper(port);
            scanner.DeviceFound += (name, host, p) =>
            {
                Dispatcher.Invoke(() =>
                {
                    _mainWindow.AddScannedDevice(name, host, p);
                });
            };

            var devices = await scanner.ScanAsync(5000);
            Dispatcher.Invoke(() =>
            {
                if (devices.Count == 0)
                {
                    _mainWindow.ShowScanStatus("未发现设备 · 请确认 Mac 端已启动服务");
                }
                else
                {
                    foreach (var (name, host, p) in devices)
                    {
                        _mainWindow.AddScannedDevice(name, host, p);
                    }
                    _mainWindow.ShowScanStatus($"发现 {devices.Count} 台设备");
                }
            });
        }

        private void OnSettingsRequested()
        {
            var settingsWindow = new SettingsWindow(_mainWindow);
            settingsWindow.Owner = _mainWindow;
            settingsWindow.ShowDialog();
        }

        protected override void OnExit(ExitEventArgs e)
        {
            _mainWindow?.Disconnect();
            base.OnExit(e);
        }
    }
}