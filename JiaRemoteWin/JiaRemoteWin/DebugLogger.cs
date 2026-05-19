using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;

namespace JiaRemoteWin
{
    public class DebugLogger
    {
        private static readonly Lazy<DebugLogger> _instance = new(() => new DebugLogger());
        public static DebugLogger Instance => _instance.Value;

        private readonly ConcurrentQueue<string> _entries = new();
        private const int MaxEntries = 5000;
        private readonly object _lock = new();

        public event Action<string> EntryAdded;

        public string FullLog
        {
            get
            {
                lock (_lock)
                {
                    var sb = new StringBuilder();
                    foreach (var entry in _entries)
                        sb.AppendLine(entry);
                    return sb.ToString();
                }
            }
        }

        private DebugLogger()
        {
            Trace.Listeners.Add(new DebugLogTraceListener());
        }

        public void Log(string message)
        {
            string timestamp = DateTime.Now.ToString("HH:mm:ss.fff");
            string entry = $"[{timestamp}] {message}";

            lock (_lock)
            {
                _entries.Enqueue(entry);
                while (_entries.Count > MaxEntries)
                    _entries.TryDequeue(out _);
            }

            EntryAdded?.Invoke(entry);
            Debug.WriteLine(entry);
        }

        public void Clear()
        {
            lock (_lock)
            {
                _entries.Clear();
            }
            EntryAdded?.Invoke(null);
        }

        private class DebugLogTraceListener : TraceListener
        {
            public override void Write(string message)
            {
                if (!string.IsNullOrWhiteSpace(message))
                    Instance.Log(message.TrimEnd());
            }

            public override void WriteLine(string message)
            {
                if (!string.IsNullOrWhiteSpace(message))
                    Instance.Log(message.TrimEnd());
            }
        }
    }

    public class DebugLogWindow : Window
    {
        private bool _autoScroll = true;

        public DebugLogWindow()
        {
            Title = "JiaRemote · 调试日志";
            Width = 700;
            Height = 500;
            MinWidth = 400;
            MinHeight = 300;
            WindowStartupLocation = WindowStartupLocation.CenterScreen;
            Background = Brushes.Black;
            Foreground = Brushes.White;

            var grid = new Grid();
            grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
            grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

            var textBox = new TextBox
            {
                IsReadOnly = true,
                FontFamily = new FontFamily("Consolas"),
                FontSize = 12,
                Background = Brushes.Black,
                Foreground = Brushes.White,
                BorderThickness = new Thickness(0),
                Padding = new Thickness(8),
                VerticalScrollBarVisibility = ScrollBarVisibility.Visible,
                HorizontalScrollBarVisibility = ScrollBarVisibility.Auto,
                TextWrapping = TextWrapping.NoWrap,
                AcceptsReturn = true,
                IsReadOnlyCaretVisible = true
            };
            Grid.SetRow(textBox, 0);

            textBox.Text = DebugLogger.Instance.FullLog;
            DebugLogger.Instance.EntryAdded += entry =>
            {
                Dispatcher.Invoke(() =>
                {
                    if (entry == null)
                    {
                        textBox.Clear();
                        return;
                    }
                    textBox.AppendText(entry + Environment.NewLine);
                    if (_autoScroll)
                        textBox.ScrollToEnd();
                });
            };

            var bottomBar = new StackPanel
            {
                Orientation = Orientation.Horizontal,
                Margin = new Thickness(8, 6, 8, 8)
            };
            Grid.SetRow(bottomBar, 1);

            var copyBtn = new Button
            {
                Content = "📋 复制全部",
                Height = 28,
                Cursor = Cursors.Hand
            };
            copyBtn.Click += (s, e) =>
            {
                try
                {
                    Clipboard.SetText(DebugLogger.Instance.FullLog);
                }
                catch { }
            };

            var clearBtn = new Button
            {
                Content = "🗑 清空",
                Height = 28,
                Margin = new Thickness(8, 0, 0, 0),
                Cursor = Cursors.Hand
            };
            clearBtn.Click += (s, e) => DebugLogger.Instance.Clear();

            var autoScrollCheck = new CheckBox
            {
                Content = "自动滚动",
                IsChecked = true,
                Foreground = Brushes.White,
                Margin = new Thickness(12, 0, 0, 0),
                VerticalAlignment = VerticalAlignment.Center
            };
            autoScrollCheck.Checked += (s, e) => _autoScroll = true;
            autoScrollCheck.Unchecked += (s, e) => _autoScroll = false;

            bottomBar.Children.Add(copyBtn);
            bottomBar.Children.Add(clearBtn);
            bottomBar.Children.Add(autoScrollCheck);

            grid.Children.Add(textBox);
            grid.Children.Add(bottomBar);

            Content = grid;

            KeyDown += (s, e) =>
            {
                if (e.Key == Key.Escape) Close();
                if (e.Key == Key.C && (Keyboard.Modifiers & ModifierKeys.Control) != 0)
                {
                    if (!string.IsNullOrEmpty(textBox.SelectedText))
                    {
                        try { Clipboard.SetText(textBox.SelectedText); } catch { }
                    }
                }
            };
        }
    }
}
