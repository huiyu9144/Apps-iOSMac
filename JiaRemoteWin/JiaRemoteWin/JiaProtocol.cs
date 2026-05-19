using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace JiaRemoteWin
{
    public static class JiaProtocol
    {
        public const int DefaultPort = 9527;
        public const int MaxFrameSize = 256 * 1024 * 1024;

        private static readonly byte[] FrameMagic = { 0x4A, 0x52, 0x4D, 0x43 };
        private static readonly byte[] CmdMagic = { 0x4A, 0x52, 0x43, 0x4D };

        public struct FrameHeader
        {
            public uint Width;
            public uint Height;
            public uint BytesPerRow;
            public uint PixelFormat;
            public ulong Timestamp;
            public ulong DataLength;

            public const int HeaderSize = 36;

            public byte[] ToBytes()
            {
                byte[] data = new byte[36];
                Array.Copy(FrameMagic, 0, data, 0, 4);
                BitConverter.GetBytes(Width).CopyTo(data, 4);
                BitConverter.GetBytes(Height).CopyTo(data, 8);
                BitConverter.GetBytes(BytesPerRow).CopyTo(data, 12);
                BitConverter.GetBytes(PixelFormat).CopyTo(data, 16);
                BitConverter.GetBytes(Timestamp).CopyTo(data, 20);
                BitConverter.GetBytes(DataLength).CopyTo(data, 28);
                return data;
            }

            public static FrameHeader? FromBytes(byte[] data)
            {
                if (data.Length < 36) return null;
                if (data[0] != FrameMagic[0] || data[1] != FrameMagic[1] ||
                    data[2] != FrameMagic[2] || data[3] != FrameMagic[3]) return null;
                return new FrameHeader
                {
                    Width = BitConverter.ToUInt32(data, 4),
                    Height = BitConverter.ToUInt32(data, 8),
                    BytesPerRow = BitConverter.ToUInt32(data, 12),
                    PixelFormat = BitConverter.ToUInt32(data, 16),
                    Timestamp = BitConverter.ToUInt64(data, 20),
                    DataLength = BitConverter.ToUInt64(data, 28)
                };
            }
        }

        public enum CommandType : uint
        {
            MouseMove = 1, MouseDown = 2, MouseUp = 3,
            MouseScroll = 4, MouseDblClick = 5,
            KeyDown = 10, KeyUp = 11, KeyCombo = 12,
            SystemCommand = 20,
            ClipboardPush = 30, ClipboardPull = 31,
            WindowListRequest = 40, WindowListResponse = 41,
            WindowFocus = 42, WindowClose = 43,
            DisplayInfoRequest = 50, DisplayInfoResponse = 51,
            Ping = 100, Pong = 101
        }

        public struct MessageHeader
        {
            public CommandType Type;
            public ulong PayloadLength;

            public const int HeaderSize = 16;

            public byte[] ToBytes()
            {
                byte[] data = new byte[16];
                Array.Copy(CmdMagic, 0, data, 0, 4);
                BitConverter.GetBytes((uint)Type).CopyTo(data, 4);
                BitConverter.GetBytes(PayloadLength).CopyTo(data, 8);
                return data;
            }

            public static MessageHeader? FromBytes(byte[] data)
            {
                if (data.Length < 16) return null;
                if (data[0] != CmdMagic[0] || data[1] != CmdMagic[1] ||
                    data[2] != CmdMagic[2] || data[3] != CmdMagic[3]) return null;
                return new MessageHeader
                {
                    Type = (CommandType)BitConverter.ToUInt32(data, 4),
                    PayloadLength = BitConverter.ToUInt64(data, 8)
                };
            }
        }

        public static byte[] EncodeCommand<T>(CommandType type, T payload)
        {
            string json = JsonSerializer.Serialize(payload);
            byte[] payloadBytes = Encoding.UTF8.GetBytes(json);
            byte[] header = new MessageHeader { Type = type, PayloadLength = (ulong)payloadBytes.Length }.ToBytes();
            byte[] result = new byte[header.Length + payloadBytes.Length];
            Array.Copy(header, 0, result, 0, header.Length);
            Array.Copy(payloadBytes, 0, result, header.Length, payloadBytes.Length);
            return result;
        }

        public static T DecodePayload<T>(byte[] payload)
        {
            try { return JsonSerializer.Deserialize<T>(payload); }
            catch { return default; }
        }

        public static byte[] EncodeFrame(byte[] pixelData, uint width, uint height, uint bytesPerRow, uint pixelFormat)
        {
            var header = new FrameHeader
            {
                Width = width, Height = height,
                BytesPerRow = bytesPerRow, PixelFormat = pixelFormat,
                Timestamp = (ulong)DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(),
                DataLength = (ulong)pixelData.Length
            };
            byte[] headerBytes = header.ToBytes();
            byte[] result = new byte[headerBytes.Length + pixelData.Length];
            Array.Copy(headerBytes, result, headerBytes.Length);
            Array.Copy(pixelData, 0, result, headerBytes.Length, pixelData.Length);
            return result;
        }
    }

    public class MousePoint { public float X { get; set; } public float Y { get; set; } }
    public class MouseButtonEvent { public int Button { get; set; } public MousePoint Point { get; set; } = new(); }
    public class MouseScrollEvent { public float DeltaY { get; set; } public float DeltaX { get; set; } public MousePoint Point { get; set; } = new(); }
    public class KeyEvent { public ushort KeyCode { get; set; } public ulong Flags { get; set; } }
    public class KeyComboEvent { public ushort[] KeyCodes { get; set; } = Array.Empty<ushort>(); public ulong Flags { get; set; } }
    public class SystemCommandEvent { public string CommandType { get; set; } = ""; }
    public class ClipboardData { public string Text { get; set; } = ""; }
    public class RemoteWindowInfo { public uint Id { get; set; } public string Title { get; set; } = ""; public string AppName { get; set; } = ""; public bool IsOnScreen { get; set; } }
    public class RemoteDisplayInfo { public uint Id { get; set; } public ushort Width { get; set; } public ushort Height { get; set; } public ushort RefreshRate { get; set; } }

    public class ConnectionStateChangedEventArgs : EventArgs
    {
        public bool Connected { get; set; }
        public string Host { get; set; } = "";
    }

    public class FrameReceivedEventArgs : EventArgs
    {
        public JiaProtocol.FrameHeader Header { get; set; }
        public byte[] PixelData { get; set; } = Array.Empty<byte>();
    }

    public class CommandReceivedEventArgs : EventArgs
    {
        public JiaProtocol.CommandType Type { get; set; }
        public byte[] Payload { get; set; } = Array.Empty<byte>();
    }
}
