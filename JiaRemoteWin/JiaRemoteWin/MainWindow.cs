using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace JiaRemoteWin
{
    public partial class MainWindow : Window
    {
        private readonly TCPClient _client;
        private D3D11Renderer _renderer;
        private bool _isLocked;
        private bool _overlayVisible;
        private int _frameCount;
        private System.Windows.Threading.DispatcherTimer _statsTimer;

        private string _selectedHost = "";
        private int _selectedPort = JiaProtocol.DefaultPort;

        public event Action<string, int> ConnectRequested;
        public event Action DisconnectRequested;
        public event Action<int> ScanRequested;
        public event Action SettingsRequested;
        public event Action ShowDebugLog;

        public int CurrentPort
        {
            get => _selectedPort;
            set
            {
                if (value > 0 && value <= 65535)
                    _selectedPort = value;
            }
        }

        public MainWindow()
        {
            InitializeComponent();

            ManualIpInput.Text = "192.168.3.19";

            _client = new TCPClient();
            _client.ConnectionStateChanged += OnConnectionStateChanged;
            _client.FrameReceived += OnFrameReceived;

            _statsTimer = new System.Windows.Threading.DispatcherTimer
            {
                Interval = TimeSpan.FromSeconds(1)
            };
            _statsTimer.Tick += OnStatsTick;
        }

        public void AddScannedDevice(string name, string host, int port)
        {
            Dispatcher.Invoke(() =>
            {
                DeviceListControl.Visibility = Visibility.Visible;

                var item = new Border
                {
                    Background = new SolidColorBrush(Color.FromArgb(0x0A, 0xFF, 0xFF, 0xFF)),
                    CornerRadius = new CornerRadius(8),
                    Padding = new Thickness(10, 8, 10, 8),
                    Margin = new Thickness(0, 0, 0, 4),
                    Cursor = Cursors.Hand,
                    Tag = (name, host, port),
                    Child = new StackPanel
                    {
                        Orientation = Orientation.Horizontal,
                        Children =
                        {
                            new Ellipse { Width = 8, Height = 8, Fill = new SolidColorBrush(Color.FromRgb(0x30, 0xD1, 0x58)), Margin = new Thickness(0, 0, 8, 0), VerticalAlignment = VerticalAlignment.Center },
                            new TextBlock { Text = name, FontSize = 13, Foreground = new SolidColorBrush(Color.FromRgb(0xCC, 0xCC, 0xCC)), VerticalAlignment = VerticalAlignment.Center },
                            new TextBlock { Text = $"  {host}", FontFamily = new FontFamily("Consolas"), FontSize = 11, Foreground = new SolidColorBrush(Color.FromRgb(0x66, 0x66, 0x66)), VerticalAlignment = VerticalAlignment.Center, Margin = new Thickness(8, 0, 0, 0) }
                        }
                    }
                };
                item.MouseLeftButtonDown += (s, e) =>
                {
                    var (n, h, p) = ((string, string, int))item.Tag;
                    SelectDevice(n, h, p);
                };
                DeviceListControl.Items.Add(item);

                if (DeviceListControl.Items.Count == 1)
                {
                    SelectDevice(name, host, port);
                }
            });
        }

        private void SelectDevice(string name, string host, int port)
        {
            _selectedHost = host;
            _selectedPort = port;
            PortInput.Text = port.ToString();
            DeviceNameText.Text = name;
            DeviceIpText.Text = host;
            DeviceDot.Fill = new SolidColorBrush(Color.FromRgb(0x30, 0xD1, 0x58));
            StatusText.Text = "已选择设备 · 点击连接";
            StatusText.Foreground = new SolidColorBrush(Color.FromRgb(0x30, 0xD1, 0x58));
        }

        public void ShowScanStatus(string msg)
        {
            Dispatcher.Invoke(() =>
            {
                StatusText.Text = msg;
            });
        }

        public void RequestShowDebugLog()
        {
            ShowDebugLog?.Invoke();
        }

        private void OnConnectionStateChanged(object sender, ConnectionStateChangedEventArgs e)
        {
            Dispatcher.Invoke(() =>
            {
                if (e.Connected)
                {
                    WelcomePanel.Visibility = Visibility.Collapsed;
                    RenderPanel.Visibility = Visibility.Visible;
                    RemoteBar.Visibility = Visibility.Visible;
                    Title = $"JiaRemote · 已连接 {e.Host}";

                    InitRenderer();
                    _statsTimer.Start();
                }
                else
                {
                    WelcomePanel.Visibility = Visibility.Visible;
                    RenderPanel.Visibility = Visibility.Collapsed;
                    RemoteBar.Visibility = Visibility.Collapsed;
                    OverlayPanel.Visibility = Visibility.Collapsed;
                    LockOverlay.Visibility = Visibility.Collapsed;
                    Title = "JiaRemote · Windows 主控端";
                    _isLocked = false;
                    _statsTimer.Stop();
                }
            });
        }

        private void InitRenderer()
        {
            _renderer?.Dispose();
            _renderer = new D3D11Renderer();

            _renderer.BitmapChanged += (s, bitmap) =>
            {
                Dispatcher.Invoke(() =>
                {
                    if (RenderPanel.Source != bitmap)
                    {
                        RenderPanel.Source = bitmap;
                        Debug.WriteLine($"[MainWindow] 🔄 Bitmap rebound to RenderPanel (new size)");
                    }
                });
            };

            _renderer.Initialize(1920, 1080);

            RenderPanel.Source = _renderer.Bitmap;

            Debug.WriteLine("[MainWindow] ✅ Renderer initialized, bitmap bound to Image");
        }

        private void OnFrameReceived(object sender, FrameReceivedEventArgs e)
        {
            if (_renderer == null || !_renderer.IsInitialized) return;
            _renderer.UpdateFrameTexture(e.PixelData, e.Header.Width, e.Header.Height, e.Header.BytesPerRow);

            _frameCount++;
        }

        private void OnStatsTick(object sender, EventArgs e)
        {
            if (!_client.IsConnected) return;
            int fps = _frameCount;
            _frameCount = 0;

            Dispatcher.Invoke(() =>
            {
                if (_overlayVisible)
                {
                    OverlayPanel.Visibility = Visibility.Visible;
                    FpsText.Text = fps.ToString();
                }
            });
        }

        public void ShowOverlay(bool show)
        {
            _overlayVisible = show;
            if (!show) OverlayPanel.Visibility = Visibility.Collapsed;
        }

        public void EnterLockMode()
        {
            _isLocked = true;
            LockOverlay.Visibility = Visibility.Visible;
            LockBtn.Content = "🔒";
            Cursor = Cursors.None;
            RenderPanel.Focus();
        }

        public void ExitLockMode()
        {
            _isLocked = false;
            LockOverlay.Visibility = Visibility.Collapsed;
            LockBtn.Content = "🔓";
            Cursor = Cursors.Arrow;
        }

        public void ToggleFullscreen()
        {
            if (WindowStyle == WindowStyle.None)
            {
                WindowStyle = WindowStyle.SingleBorderWindow;
                WindowState = WindowState.Normal;
                ResizeMode = ResizeMode.CanResize;
                Topmost = false;
            }
            else
            {
                WindowStyle = WindowStyle.None;
                WindowState = WindowState.Maximized;
                ResizeMode = ResizeMode.NoResize;
                Topmost = true;
            }
        }

        public async Task ConnectAsync(string host, int port)
        {
            StatusText.Text = "正在连接...";
            StatusText.Foreground = new SolidColorBrush(Color.FromRgb(0xFF, 0x9F, 0x0A));
            try
            {
                await _client.ConnectAsync(host, port);
            }
            catch (Exception ex)
            {
                StatusText.Text = $"连接失败: {ex.Message}";
                StatusText.Foreground = new SolidColorBrush(Color.FromRgb(0xFF, 0x45, 0x3A));
            }
        }

        public void Disconnect()
        {
            _client.Disconnect();
            _renderer?.Dispose();
            _renderer = null;
            StatusText.Text = "已断开 · 请先扫描局域网设备";
            StatusText.Foreground = new SolidColorBrush(Color.FromRgb(0x66, 0x66, 0x66));
        }

        private void SendMouseMove(Point pos)
        {
            if (!_client.IsConnected) return;
            double normX = pos.X / RenderPanel.ActualWidth;
            double normY = pos.Y / RenderPanel.ActualHeight;
            _ = _client.SendCommand(JiaProtocol.CommandType.MouseMove,
                new MousePoint { X = (float)normX, Y = (float)normY });
        }

        private void SendMouseButton(Point pos, int button, bool isDown)
        {
            if (!_client.IsConnected) return;
            double normX = pos.X / RenderPanel.ActualWidth;
            double normY = pos.Y / RenderPanel.ActualHeight;
            var evt = new MouseButtonEvent
            {
                Button = button,
                Point = new MousePoint { X = (float)normX, Y = (float)normY }
            };
            _ = _client.SendCommand(isDown ? JiaProtocol.CommandType.MouseDown : JiaProtocol.CommandType.MouseUp, evt);
        }

        private void SendKey(Key key, bool isDown)
        {
            if (!_client.IsConnected) return;
            var (keyCode, flags) = WindowsKeyMapper.MapKey(key, isDown);
            if (keyCode == 0xFFFF) return;
            _ = _client.SendCommand(isDown ? JiaProtocol.CommandType.KeyDown : JiaProtocol.CommandType.KeyUp,
                new KeyEvent { KeyCode = keyCode, Flags = flags });
        }

        public async Task SendSystemCommand(string cmd)
        {
            if (!_client.IsConnected) return;
            await _client.SendCommand(JiaProtocol.CommandType.SystemCommand,
                new SystemCommandEvent { CommandType = cmd });
        }

        // ── 鼠标事件 ──
        private void RenderPanel_MouseMove(object sender, MouseEventArgs e)
        {
            if (!_isLocked || !_client.IsConnected) return;
            SendMouseMove(e.GetPosition(RenderPanel));
        }

        private void RenderPanel_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            if (!_isLocked || !_client.IsConnected) return;
            RenderPanel.CaptureMouse();
            SendMouseButton(e.GetPosition(RenderPanel), 0, true);
        }

        private void RenderPanel_MouseLeftButtonUp(object sender, MouseButtonEventArgs e)
        {
            if (!_isLocked || !_client.IsConnected) return;
            RenderPanel.ReleaseMouseCapture();
            SendMouseButton(e.GetPosition(RenderPanel), 0, false);
        }

        private void RenderPanel_MouseRightButtonDown(object sender, MouseButtonEventArgs e)
        {
            if (!_isLocked || !_client.IsConnected) return;
            SendMouseButton(e.GetPosition(RenderPanel), 1, true);
        }

        private void RenderPanel_MouseRightButtonUp(object sender, MouseButtonEventArgs e)
        {
            if (!_isLocked || !_client.IsConnected) return;
            SendMouseButton(e.GetPosition(RenderPanel), 1, false);
        }

        private void RenderPanel_MouseWheel(object sender, MouseWheelEventArgs e)
        {
            if (!_isLocked || !_client.IsConnected) return;
            _ = _client.SendCommand(JiaProtocol.CommandType.MouseScroll,
                new MouseScrollEvent { DeltaY = e.Delta / 120f, DeltaX = 0, Point = new MousePoint() });
        }

        // ── 键盘事件 ──
        private void Window_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.LeftCtrl || e.Key == Key.RightCtrl ||
                e.Key == Key.LeftAlt || e.Key == Key.RightAlt) return;

            if (_isLocked && Keyboard.Modifiers == (ModifierKeys.Control | ModifierKeys.Alt))
            {
                ExitLockMode();
                return;
            }

            if (_isLocked && _client.IsConnected)
            {
                SendKey(e.Key, true);
                e.Handled = true;
            }
        }

        private void Window_KeyUp(object sender, KeyEventArgs e)
        {
            if (_isLocked && _client.IsConnected)
            {
                SendKey(e.Key, false);
                e.Handled = true;
            }
        }

        // ── 按钮事件 ──
        private void ConnectBtn_Click(object sender, RoutedEventArgs e)
        {
            string host = _selectedHost;
            int port = _selectedPort;

            if (string.IsNullOrEmpty(host))
            {
                StatusText.Text = "请先扫描设备或输入 IP 地址";
                StatusText.Foreground = new SolidColorBrush(Color.FromRgb(0xFF, 0x9F, 0x0A));
                return;
            }

            ConnectRequested?.Invoke(host, port);
        }

        private void ScanBtn_Click(object sender, RoutedEventArgs e)
        {
            DeviceListControl.Items.Clear();
            DeviceListControl.Visibility = Visibility.Collapsed;
            StatusText.Text = "正在扫描局域网 Mac 设备...";
            StatusText.Foreground = new SolidColorBrush(Color.FromRgb(0xFF, 0x9F, 0x0A));
            ScanRequested?.Invoke(_selectedPort);
        }

        private void PortInput_PreviewTextInput(object sender, System.Windows.Input.TextCompositionEventArgs e)
        {
            foreach (char c in e.Text)
            {
                if (!char.IsDigit(c))
                {
                    e.Handled = true;
                    return;
                }
            }
        }

        private void PortInput_TextChanged(object sender, System.Windows.Controls.TextChangedEventArgs e)
        {
            if (int.TryParse(PortInput.Text, out int port))
            {
                if (port > 0 && port <= 65535)
                {
                    _selectedPort = port;
                }
            }
        }

        private void ManualIpInput_TextChanged(object sender, System.Windows.Controls.TextChangedEventArgs e)
        {
            if (DeviceNameText == null || DeviceIpText == null || StatusText == null) return;

            string ip = ManualIpInput.Text.Trim();
            if (!string.IsNullOrEmpty(ip))
            {
                _selectedHost = ip;
                DeviceNameText.Text = "手动连接";
                DeviceIpText.Text = ip;
                DeviceDot.Fill = new SolidColorBrush(Color.FromRgb(0x0A, 0x84, 0xFF));
                StatusText.Text = "输入 IP · 点击连接";
                StatusText.Foreground = new SolidColorBrush(Color.FromRgb(0x0A, 0x84, 0xFF));
            }
        }

        private void SettingsBtn_Click(object sender, RoutedEventArgs e)
        {
            SettingsRequested?.Invoke();
        }

        private void LockBtn_Click(object sender, RoutedEventArgs e)
        {
            if (_isLocked) ExitLockMode(); else EnterLockMode();
        }

        private void DisconnectBtn_Click(object sender, RoutedEventArgs e)
        {
            DisconnectRequested?.Invoke();
        }

        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        {
            _client?.Disconnect();
            _renderer?.Dispose();
            _statsTimer?.Stop();
        }

        protected override void OnRenderSizeChanged(SizeChangedInfo sizeInfo)
        {
            base.OnRenderSizeChanged(sizeInfo);
        }
    }
}