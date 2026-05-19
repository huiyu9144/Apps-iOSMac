using System;
using System.Diagnostics;
using System.Text;

namespace JiaRemoteWin
{
    public class DebugLogListener : TraceListener
    {
        private readonly int _maxLines = 500;
        private readonly object _lock = new object();

        public event Action<string> LogReceived;

        public override void Write(string message)
        {
            Emit(message);
        }

        public override void WriteLine(string message)
        {
            Emit(message + Environment.NewLine);
        }

        private void Emit(string message)
        {
            if (string.IsNullOrWhiteSpace(message)) return;
            string line = $"[{DateTime.Now:HH:mm:ss.fff}] {message.Trim()}";
            LogReceived?.Invoke(line);
        }
    }
}