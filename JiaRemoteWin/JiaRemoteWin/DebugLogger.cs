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
}
