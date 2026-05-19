using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;

namespace JiaRemoteWin
{
    public partial class SettingsWindow : Window
    {
        private readonly MainWindow _main;
        private bool _lockOn;
        private bool _overlayOn;
        private bool _fullscreenOn;

        public SettingsWindow(MainWindow main)
        {
            InitializeComponent();
            _main = main;

            Loaded += (s, e) =>
            {
                Opacity = 0;
                var anim = new DoubleAnimation(0, 1, TimeSpan.FromMilliseconds(300))
                {
                    EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut }
                };
                BeginAnimation(OpacityProperty, anim);
            };
        }

        private void AnimateToggleKnob(Border knob, double from, double to, bool instant)
        {
            knob.Margin = new Thickness(0, 0, instant ? (to > 0 ? 1 : 21) : from == 0 ? 21 : 1, 0);
            var anim = new ThicknessAnimation
            {
                From = new Thickness(0, 0, from, 0),
                To = new Thickness(0, 0, to, 0),
                Duration = TimeSpan.FromMilliseconds(260),
                EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut }
            };
            knob.BeginAnimation(MarginProperty, anim);
        }

        private void SetToggleState(Border bg, Border knob, bool on)
        {
            bg.Background = on
                ? new SolidColorBrush(Color.FromRgb(0x0A, 0x84, 0xFF))
                : new SolidColorBrush(Color.FromArgb(0x33, 0xFF, 0xFF, 0xFF));
            knob.Margin = new Thickness(0, 0, on ? 1 : 21, 0);
        }

        private void LockRow_Click(object sender, MouseButtonEventArgs e)
        {
            _lockOn = !_lockOn;
            SetToggleState(ToggleBg_Lock, ToggleKnob_Lock, _lockOn);
            AnimateToggleKnob(ToggleKnob_Lock, _lockOn ? 21 : 1, _lockOn ? 1 : 21, false);
            if (_lockOn) _main.EnterLockMode(); else _main.ExitLockMode();
        }

        private void OverlayRow_Click(object sender, MouseButtonEventArgs e)
        {
            _overlayOn = !_overlayOn;
            SetToggleState(ToggleBg_Overlay, ToggleKnob_Overlay, _overlayOn);
            AnimateToggleKnob(ToggleKnob_Overlay, _overlayOn ? 21 : 1, _overlayOn ? 1 : 21, false);
            _main.ShowOverlay(_overlayOn);
        }

        private void FullscreenRow_Click(object sender, MouseButtonEventArgs e)
        {
            _fullscreenOn = !_fullscreenOn;
            SetToggleState(ToggleBg_Fullscreen, ToggleKnob_Fullscreen, _fullscreenOn);
            AnimateToggleKnob(ToggleKnob_Fullscreen, _fullscreenOn ? 21 : 1, _fullscreenOn ? 1 : 21, false);
            _main.ToggleFullscreen();
        }

        private async void QuickBtn_Click(object sender, RoutedEventArgs e)
        {
            var btn = sender as Button;
            var cmd = btn?.Tag?.ToString() ?? "";
            await _main.SendSystemCommand(cmd);

            var scale = new ScaleTransform(1, 1);
            btn.RenderTransform = scale;
            btn.RenderTransformOrigin = new Point(0.5, 0.5);
            var anim = new DoubleAnimation(1, 0.88, TimeSpan.FromMilliseconds(80))
            {
                AutoReverse = true,
                EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut }
            };
            scale.BeginAnimation(ScaleTransform.ScaleXProperty, anim);
            scale.BeginAnimation(ScaleTransform.ScaleYProperty, anim);
        }

        private async void ClipPush_Click(object sender, RoutedEventArgs e)
        {
            await _main.SendSystemCommand("clipboardPush");
        }

        private async void ClipPull_Click(object sender, RoutedEventArgs e)
        {
            await _main.SendSystemCommand("clipboardPull");
        }

        private void DebugLogRow_Click(object sender, MouseButtonEventArgs e)
        {
            _main.RequestShowDebugLog();
        }

        private void CloseBtn_Click(object sender, RoutedEventArgs e)
        {
            var anim = new DoubleAnimation(1, 0, TimeSpan.FromMilliseconds(180))
            {
                EasingFunction = new CubicEase { EasingMode = EasingMode.EaseIn }
            };
            anim.Completed += (s2, e2) => Close();
            BeginAnimation(OpacityProperty, anim);
        }

        private void TitleBar_MouseDown(object sender, MouseButtonEventArgs e)
        {
            if (e.LeftButton == MouseButtonState.Pressed)
                DragMove();
        }
    }
}
