using System;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace JiaRemoteWin
{
    public partial class DebugLogWindow : Window
    {
        private readonly StringBuilder _sb = new StringBuilder();
        private int _lineCount;
        private const int MaxLines = 2000;

        public DebugLogWindow()
        {
            InitializeComponent();
            LogText.Text = "";
        }

        public void AppendLine(string line)
        {
            Dispatcher.Invoke(() =>
            {
                if (_lineCount >= MaxLines)
                {
                    int firstNewline = _sb.ToString().IndexOf('\n');
                    if (firstNewline >= 0)
                        _sb.Remove(0, firstNewline + 1);
                    else
                        _sb.Clear();
                    _lineCount = _sb.ToString().Split('\n').Length - 1;
                }

                _sb.AppendLine(line);
                _lineCount++;

                LogText.Text = _sb.ToString();
                LineCountText.Text = $"{_lineCount} 行";
                StatusText.Text = $"最后更新: {DateTime.Now:HH:mm:ss}";

                LogText.ScrollToEnd();
            });
        }

        private void ClearBtn_Click(object sender, RoutedEventArgs e)
        {
            _sb.Clear();
            _lineCount = 0;
            LogText.Text = "";
            LineCountText.Text = "0 行";
        }

        private void CloseBtn_Click(object sender, RoutedEventArgs e)
        {
            Close();
        }

        private void TitleBar_MouseDown(object sender, MouseButtonEventArgs e)
        {
            if (e.ChangedButton == MouseButton.Left)
                DragMove();
        }
    }
}