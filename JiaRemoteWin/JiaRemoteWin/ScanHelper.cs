using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;

namespace JiaRemoteWin
{
    public class ScanHelper
    {
        private readonly int _port;

        public event Action<string, string, int> DeviceFound;

        public ScanHelper(int port = JiaProtocol.DefaultPort)
        {
            _port = port;
        }

        public async Task<List<(string Name, string Host, int Port)>> ScanAsync(int timeoutMs = 5000)
        {
            var results = new List<(string, string, int)>();
            var deadline = DateTime.UtcNow.AddMilliseconds(timeoutMs);

            // Phase 1: UDP broadcast scanning
            Debug.WriteLine("[ScanHelper] Phase 1: UDP broadcast scan");
            await UdpScanAsync(results, deadline);

            // Phase 2: TCP subnet scan (if we still have time)
            if (DateTime.UtcNow < deadline && results.Count == 0)
            {
                Debug.WriteLine("[ScanHelper] Phase 2: TCP subnet scan");
                await TcpSubnetScanAsync(results, deadline);
            }

            // Phase 3: Direct TCP connections to common IPs (.1-.254 on each local subnet)
            if (DateTime.UtcNow < deadline && results.Count == 0)
            {
                Debug.WriteLine("[ScanHelper] Phase 3: Direct TCP probe on all subnet IPs");
                await TcpProbeAllAsync(results, deadline);
            }

            Debug.WriteLine($"[ScanHelper] Scan complete, found {results.Count} devices");
            return results;
        }

        private async Task UdpScanAsync(List<(string, string, int)> results, DateTime deadline)
        {
            try
            {
                using var udp = new UdpClient { EnableBroadcast = true };
                udp.Client.ReceiveTimeout = 500;

                var probeData = Encoding.UTF8.GetBytes("JR_SCAN");

                // Send to global broadcast
                await udp.SendAsync(probeData, probeData.Length,
                    new IPEndPoint(IPAddress.Broadcast, _port));

                // Also send to each subnet's broadcast address
                foreach (var subnetBcast in GetSubnetBroadcastAddresses())
                {
                    try
                    {
                        await udp.SendAsync(probeData, probeData.Length,
                            new IPEndPoint(subnetBcast, _port));
                    }
                    catch { }
                }

                Debug.WriteLine($"[ScanHelper] UDP probes sent, listening for responses...");

                while (DateTime.UtcNow < deadline)
                {
                    try
                    {
                        var result = await udp.ReceiveAsync();
                        string msg = Encoding.UTF8.GetString(result.Buffer);
                        Debug.WriteLine($"[ScanHelper] UDP received: {msg} from {result.RemoteEndPoint}");

                        if (msg.StartsWith("JR_HOST:"))
                        {
                            var parts = msg[8..].Split('|');
                            string name = parts.Length > 0 ? parts[0] : "Unknown";
                            string host = parts.Length > 1 && !string.IsNullOrEmpty(parts[1])
                                ? parts[1]
                                : result.RemoteEndPoint.Address.ToString();
                            var key = (name, host, _port);
                            if (!results.Contains(key))
                            {
                                results.Add(key);
                                DeviceFound?.Invoke(name, host, _port);
                                Debug.WriteLine($"[ScanHelper] Found device: {name} @ {host}");
                            }
                        }
                    }
                    catch (SocketException)
                    {
                        break;
                    }
                    catch (ObjectDisposedException)
                    {
                        break;
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[ScanHelper] UDP scan error: {ex.Message}");
            }
        }

        private async Task TcpSubnetScanAsync(List<(string, string, int)> results, DateTime deadline)
        {
            var subnetHosts = GetLocalSubnetHosts();
            var tasks = subnetHosts.Select(host => TcpProbeAsync(host, _port, 500));
            var probeResults = await Task.WhenAll(tasks);

            foreach (var (host, ok) in probeResults)
            {
                if (ok && DateTime.UtcNow < deadline)
                {
                    string name = $"Mac @ {host}";
                    var key = (name, host, _port);
                    if (!results.Contains(key))
                    {
                        results.Add(key);
                        DeviceFound?.Invoke(name, host, _port);
                        Debug.WriteLine($"[ScanHelper] TCP subnet found: {host}");
                    }
                }
            }
        }

        private async Task TcpProbeAllAsync(List<(string, string, int)> results, DateTime deadline)
        {
            var seenSubnets = new HashSet<string>();
            var allTargets = new List<string>();

            foreach (var ni in NetworkInterface.GetAllNetworkInterfaces())
            {
                if (ni.OperationalStatus != OperationalStatus.Up) continue;
                foreach (var addr in ni.GetIPProperties().UnicastAddresses)
                {
                    if (addr.Address.AddressFamily != AddressFamily.InterNetwork) continue;
                    var ip = addr.Address;
                    var mask = addr.IPv4Mask;
                    if (mask == null) continue;

                    byte[] ipB = ip.GetAddressBytes();
                    byte[] maskB = mask.GetAddressBytes();
                    byte[] netB = new byte[4];
                    for (int j = 0; j < 4; j++)
                        netB[j] = (byte)(ipB[j] & maskB[j]);

                    string subnetKey = $"{netB[0]}.{netB[1]}.{netB[2]}.{netB[3]}";
                    if (!seenSubnets.Add(subnetKey)) continue;

                    for (int i = 1; i <= 254; i++)
                    {
                        byte[] target = new byte[4];
                        for (int j = 0; j < 4; j++)
                            target[j] = (byte)(netB[j] | (i & ~maskB[j]));
                        var testIp = new IPAddress(target);
                        if (!testIp.Equals(ip))
                            allTargets.Add(testIp.ToString());
                    }
                }
            }

            Debug.WriteLine($"[ScanHelper] Probing {allTargets.Count} IPs via TCP...");

            int batchSize = 30;
            for (int b = 0; b < allTargets.Count && DateTime.UtcNow < deadline; b += batchSize)
            {
                var batch = allTargets.Skip(b).Take(batchSize);
                var tasks = batch.Select(host => TcpProbeAsync(host, _port, 400));
                var batchResults = await Task.WhenAll(tasks);
                foreach (var (host, ok) in batchResults)
                {
                    if (ok)
                    {
                        string name = $"Mac @ {host}";
                        var key = (name, host, _port);
                        if (!results.Contains(key))
                        {
                            results.Add(key);
                            DeviceFound?.Invoke(name, host, _port);
                            Debug.WriteLine($"[ScanHelper] TCP found: {host}");
                        }
                    }
                }
            }
        }

        private static async Task<(string host, bool ok)> TcpProbeAsync(string host, int port, int timeoutMs)
        {
            try
            {
                using var client = new TcpClient();
                var task = client.ConnectAsync(host, port);
                var completed = await Task.WhenAny(task, Task.Delay(timeoutMs));
                if (completed == task && client.Connected)
                {
                    try
                    {
                        // Try to verify it's a JiaRemote server by reading the initial greeting
                        var stream = client.GetStream();
                        var buffer = new byte[32];
                        var readTask = stream.ReadAsync(buffer, 0, buffer.Length);
                        var readCompleted = await Task.WhenAny(readTask, Task.Delay(200));
                        if (readCompleted == readTask && readTask.Result > 0)
                        {
                            string greeting = Encoding.UTF8.GetString(buffer, 0, readTask.Result);
                            if (greeting.Contains("JR_READY"))
                            {
                                return (host, true);
                            }
                        }
                    }
                    catch
                    {
                        // Connection established but couldn't verify - still consider it found
                        return (host, true);
                    }
                    return (host, true);
                }
                return (host, false);
            }
            catch
            {
                return (host, false);
            }
        }

        private static List<string> GetLocalSubnetHosts()
        {
            var hosts = new HashSet<string>();
            foreach (var ni in NetworkInterface.GetAllNetworkInterfaces())
            {
                if (ni.OperationalStatus != OperationalStatus.Up) continue;
                foreach (var addr in ni.GetIPProperties().UnicastAddresses)
                {
                    if (addr.Address.AddressFamily != AddressFamily.InterNetwork) continue;
                    var ip = addr.Address;
                    var mask = addr.IPv4Mask;
                    if (mask == null) continue;
                    byte[] ipB = ip.GetAddressBytes();
                    byte[] maskB = mask.GetAddressBytes();

                    int hostBits = 0;
                    for (int j = 0; j < 4; j++)
                        for (int b = 0; b < 8; b++)
                            if ((maskB[j] & (1 << (7 - b))) == 0)
                                hostBits++;

                    int maxHosts = hostBits < 8 ? (1 << hostBits) - 2 : 254;
                    if (maxHosts > 254) maxHosts = 254;

                    for (int i = 1; i <= maxHosts; i++)
                    {
                        byte[] target = new byte[4];
                        for (int j = 0; j < 4; j++)
                            target[j] = (byte)((ipB[j] & maskB[j]) | (i & ~maskB[j]));
                        var testIp = new IPAddress(target);
                        if (!testIp.Equals(ip))
                            hosts.Add(testIp.ToString());
                    }
                }
            }
            return hosts.ToList();
        }

        private static List<IPAddress> GetSubnetBroadcastAddresses()
        {
            var broadcasts = new HashSet<IPAddress>();
            foreach (var ni in NetworkInterface.GetAllNetworkInterfaces())
            {
                if (ni.OperationalStatus != OperationalStatus.Up) continue;
                foreach (var addr in ni.GetIPProperties().UnicastAddresses)
                {
                    if (addr.Address.AddressFamily != AddressFamily.InterNetwork) continue;
                    var ip = addr.Address;
                    var mask = addr.IPv4Mask;
                    if (mask == null) continue;

                    byte[] ipB = ip.GetAddressBytes();
                    byte[] maskB = mask.GetAddressBytes();
                    byte[] bcast = new byte[4];
                    for (int j = 0; j < 4; j++)
                        bcast[j] = (byte)(ipB[j] | ~maskB[j]);
                    broadcasts.Add(new IPAddress(bcast));
                }
            }
            return broadcasts.ToList();
        }
    }
}