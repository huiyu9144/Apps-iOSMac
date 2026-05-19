using System;
using System.Diagnostics;
using System.IO;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace JiaRemoteWin
{
    public class TCPClient : IDisposable
    {
        private TcpClient _frameClient;
        private TcpClient _cmdClient;
        private NetworkStream _frameStream;
        private NetworkStream _cmdStream;
        private CancellationTokenSource _cts;

        private readonly byte[] _recvBuffer = new byte[65536];

        public bool IsConnected { get; private set; }
        public string ConnectedHost { get; private set; } = "";

        public event EventHandler<ConnectionStateChangedEventArgs> ConnectionStateChanged;
        public event EventHandler<FrameReceivedEventArgs> FrameReceived;
        public event EventHandler<CommandReceivedEventArgs> CommandReceived;

        public async Task ConnectAsync(string host, int port = JiaProtocol.DefaultPort)
        {
            Disconnect();

            _cts = new CancellationTokenSource();
            var ct = _cts.Token;

            try
            {
                Debug.WriteLine($"[TCP] === 开始连接 {host}:{port} ===");

                _frameClient = new TcpClient { NoDelay = true, ReceiveBufferSize = 4 * 1024 * 1024, SendBufferSize = 4 * 1024 * 1024 };
                _cmdClient = new TcpClient { NoDelay = true, ReceiveBufferSize = 65536, SendBufferSize = 65536 };

                Debug.WriteLine("[TCP] 连接帧通道...");
                await _frameClient.ConnectAsync(host, port).WaitAsync(ct);
                _frameStream = _frameClient.GetStream();
                Debug.WriteLine("[TCP] 帧通道 TCP 已连接");

                Debug.WriteLine("[TCP] 连接命令通道...");
                await _cmdClient.ConnectAsync(host, port).WaitAsync(ct);
                _cmdStream = _cmdClient.GetStream();
                Debug.WriteLine("[TCP] 命令通道 TCP 已连接");

                string frameGreeting = await ReadLineAsync(_frameStream, ct, "帧通道");
                Debug.WriteLine($"[TCP] 帧通道收到: '{frameGreeting}'");

                string cmdGreeting = await ReadLineAsync(_cmdStream, ct, "命令通道");
                Debug.WriteLine($"[TCP] 命令通道收到: '{cmdGreeting}'");

                if (!frameGreeting.Contains("JR_READY"))
                    throw new Exception($"帧通道握手失败，期望 JR_READY，得到: {frameGreeting}");
                if (!cmdGreeting.Contains("JR_READY"))
                    throw new Exception($"命令通道握手失败，期望 JR_READY，得到: {cmdGreeting}");

                byte[] frameId = Encoding.ASCII.GetBytes("JR_FRAME");
                byte[] cmdId = Encoding.ASCII.GetBytes("JR_CMD");

                await _frameStream.WriteAsync(frameId, 0, frameId.Length, ct);
                await _frameStream.FlushAsync(ct);
                Debug.WriteLine("[TCP] 已发送 JR_FRAME 标识");

                await _cmdStream.WriteAsync(cmdId, 0, cmdId.Length, ct);
                await _cmdStream.FlushAsync(ct);
                Debug.WriteLine("[TCP] 已发送 JR_CMD 标识");

                IsConnected = true;
                ConnectedHost = host;
                Debug.WriteLine($"[TCP] ✅ 双通道握手完成！已连接 {host}:{port}");

                ConnectionStateChanged?.Invoke(this, new ConnectionStateChangedEventArgs { Connected = true, Host = host });

                _ = Task.Run(() => FrameReceiveLoop(ct));
                _ = Task.Run(() => CommandReceiveLoop(ct));
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[TCP] ❌ 连接失败: {ex.Message}\n{ex.StackTrace}");
                Disconnect();
                throw;
            }
        }

        private async Task<string> ReadLineAsync(NetworkStream stream, CancellationToken ct, string channelName)
        {
            try
            {
                var sb = new StringBuilder();
                var buf = new byte[1];
                var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(ct);
                timeoutCts.CancelAfter(TimeSpan.FromSeconds(10));

                while (!timeoutCts.Token.IsCancellationRequested)
                {
                    int read = await stream.ReadAsync(buf, 0, 1, timeoutCts.Token);
                    if (read == 0) throw new EndOfStreamException($"{channelName} 连接关闭");
                    char c = (char)buf[0];
                    if (c == '\n' || c == '\r') break;
                    sb.Append(c);
                    if (sb.Length > 64) break;
                }

                return sb.ToString();
            }
            catch (OperationCanceledException)
            {
                throw new TimeoutException($"{channelName} 握手超时（10秒内未收到 JR_READY）");
            }
        }

        public void Disconnect()
        {
            Debug.WriteLine("[TCP] 断开连接");
            IsConnected = false;
            _cts?.Cancel();
            _cts?.Dispose();
            _cts = null;

            try { _frameStream?.Close(); } catch { }
            try { _cmdStream?.Close(); } catch { }
            try { _frameClient?.Close(); } catch { }
            try { _cmdClient?.Close(); } catch { }

            _frameStream = null;
            _cmdStream = null;
            _frameClient = null;
            _cmdClient = null;

            ConnectionStateChanged?.Invoke(this, new ConnectionStateChangedEventArgs { Connected = false });
        }

        private async Task FrameReceiveLoop(CancellationToken ct)
        {
            byte[] headerBuf = new byte[JiaProtocol.FrameHeader.HeaderSize];
            byte[] pixelBuf = null;

            Debug.WriteLine("[TCP] 帧接收循环启动");

            while (!ct.IsCancellationRequested && IsConnected && _frameStream != null)
            {
                try
                {
                    await ReadExactAsync(_frameStream, headerBuf, 0, headerBuf.Length, ct);
                    var header = JiaProtocol.FrameHeader.FromBytes(headerBuf);
                    if (header == null)
                    {
                        Debug.WriteLine("[TCP] ⚠️ 帧头 magic 不匹配，跳过字节");
                        continue;
                    }

                    if (pixelBuf == null || pixelBuf.Length < (long)header.Value.DataLength)
                        pixelBuf = new byte[header.Value.DataLength];

                    await ReadExactAsync(_frameStream, pixelBuf, 0, (int)header.Value.DataLength, ct);

                    FrameReceived?.Invoke(this, new FrameReceivedEventArgs
                    {
                        Header = header.Value,
                        PixelData = pixelBuf
                    });
                }
                catch (OperationCanceledException) { Debug.WriteLine("[TCP] 帧接收循环取消"); break; }
                catch (Exception ex)
                {
                    Debug.WriteLine($"[TCP] 帧接收错误: {ex.Message}");
                    break;
                }
            }
            Debug.WriteLine("[TCP] 帧接收循环退出");
        }

        private async Task CommandReceiveLoop(CancellationToken ct)
        {
            var cmdBuffer = new System.Collections.Generic.List<byte>();
            byte[] tempBuf = new byte[4096];

            Debug.WriteLine("[TCP] 命令接收循环启动");

            while (!ct.IsCancellationRequested && IsConnected && _cmdStream != null)
            {
                try
                {
                    int read = await _cmdStream.ReadAsync(tempBuf, 0, tempBuf.Length, ct);
                    if (read == 0) { Debug.WriteLine("[TCP] 命令流 EOF"); break; }

                    cmdBuffer.AddRange(new ArraySegment<byte>(tempBuf, 0, read));

                    while (cmdBuffer.Count >= JiaProtocol.MessageHeader.HeaderSize)
                    {
                        var msgHeader = JiaProtocol.MessageHeader.FromBytes(cmdBuffer.ToArray());
                        if (msgHeader == null)
                        {
                            cmdBuffer.RemoveAt(0);
                            continue;
                        }

                        long totalSize = JiaProtocol.MessageHeader.HeaderSize + (long)msgHeader.Value.PayloadLength;
                        if (cmdBuffer.Count < totalSize) break;

                        byte[] payload = new byte[msgHeader.Value.PayloadLength];
                        Array.Copy(cmdBuffer.ToArray(), JiaProtocol.MessageHeader.HeaderSize, payload, 0, (int)msgHeader.Value.PayloadLength);

                        CommandReceived?.Invoke(this, new CommandReceivedEventArgs
                        {
                            Type = msgHeader.Value.Type,
                            Payload = payload
                        });

                        cmdBuffer.RemoveRange(0, (int)totalSize);
                    }
                }
                catch (OperationCanceledException) { Debug.WriteLine("[TCP] 命令接收循环取消"); break; }
                catch (Exception ex)
                {
                    Debug.WriteLine($"[TCP] 命令接收错误: {ex.Message}");
                    break;
                }
            }
            Debug.WriteLine("[TCP] 命令接收循环退出");
        }

        public async Task SendCommand<T>(JiaProtocol.CommandType type, T payload)
        {
            if (_cmdStream == null || !IsConnected) return;
            try
            {
                byte[] data = JiaProtocol.EncodeCommand(type, payload);
                await _cmdStream.WriteAsync(data, 0, data.Length);
                await _cmdStream.FlushAsync();
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[TCP] 发送命令错误: {ex.Message}");
            }
        }

        private static async Task ReadExactAsync(NetworkStream stream, byte[] buffer, int offset, int count, CancellationToken ct)
        {
            int totalRead = 0;
            while (totalRead < count)
            {
                int read = await stream.ReadAsync(buffer, offset + totalRead, count - totalRead, ct);
                if (read == 0) throw new EndOfStreamException("Connection closed");
                totalRead += read;
            }
        }

        public void Dispose()
        {
            Disconnect();
        }
    }
}