using System;
using System.Diagnostics;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace JiaRemoteWin
{
    public class D3D11Renderer : IDisposable
    {
        private WriteableBitmap _bitmap;
        private int _texWidth;
        private int _texHeight;
        private readonly object _lock = new object();
        private long _frameCount;
        private long _totalBytesWritten;

        public bool IsInitialized { get; private set; }
        public WriteableBitmap Bitmap => _bitmap;

        public void Initialize(int width, int height)
        {
            lock (_lock)
            {
                _texWidth = width > 0 ? width : 1920;
                _texHeight = height > 0 ? height : 1080;

                CreateBitmap(_texWidth, _texHeight);

                IsInitialized = true;
                Debug.WriteLine($"[Renderer] ✅ Initialized {_texWidth}x{_texHeight}");
            }
        }

        private void CreateBitmap(int width, int height)
        {
            _bitmap = new WriteableBitmap(width, height, 96, 96, PixelFormats.Bgra32, null);
            Debug.WriteLine($"[Renderer] 🖼 Created new Bitmap {width}x{height}, stride={_bitmap.BackBufferStride}");
        }

        public void UpdateFrameTexture(byte[] pixelData, uint width, uint height, uint bytesPerRow)
        {
            lock (_lock)
            {
                if (!IsInitialized)
                {
                    Debug.WriteLine("[Renderer] ⚠️ UpdateFrameTexture called but not initialized!");
                    return;
                }

                int w = (int)width;
                int h = (int)height;

                if (w <= 0 || h <= 0)
                {
                    Debug.WriteLine($"[Renderer] ⚠️ Invalid frame size: {w}x{h}");
                    return;
                }

                bool needNewBitmap = (_bitmap == null || w != _texWidth || h != _texHeight);
                if (needNewBitmap)
                {
                    Debug.WriteLine($"[Renderer] 📐 Size changed: {_texWidth}x{_texHeight} → {w}x{h}, recreating bitmap");
                    _texWidth = w;
                    _texHeight = h;
                    CreateBitmap(w, h);
                }

                try
                {
                    _bitmap.Lock();

                    int srcStride = (int)bytesPerRow;
                    int dstStride = _bitmap.BackBufferStride;
                    long expectedBytes = (long)h * srcStride;

                    Debug.WriteLine($"[Renderer] 📥 Frame #{++_frameCount}: {w}x{h}, srcStride={srcStride}, dstStride={dstStride}, dataLen={pixelData.Length}, expected={expectedBytes}");

                    int rowsToCopy = Math.Min(h, pixelData.Length / Math.Max(srcStride, 1));
                    if (srcStride == dstStride)
                    {
                        int copyLength = Math.Min(pixelData.Length, rowsToCopy * dstStride);
                        System.Runtime.InteropServices.Marshal.Copy(
                            pixelData, 0,
                            _bitmap.BackBuffer,
                            copyLength);
                        _totalBytesWritten += copyLength;
                    }
                    else
                    {
                        int copyBytes = Math.Min(srcStride, dstStride);
                        unsafe
                        {
                            byte* dstPtr = (byte*)_bitmap.BackBuffer.ToPointer();
                            fixed (byte* srcPtr = pixelData)
                            {
                                for (int y = 0; y < rowsToCopy; y++)
                                {
                                    long srcOffset = (long)y * srcStride;
                                    long dstOffset = (long)y * dstStride;
                                    Buffer.MemoryCopy(
                                        srcPtr + srcOffset,
                                        dstPtr + dstOffset,
                                        copyBytes, copyBytes);
                                }
                            }
                        }
                        _totalBytesWritten += (long)rowsToCopy * copyBytes;
                    }

                    _bitmap.AddDirtyRect(new Int32Rect(0, 0, w, rowsToCopy));

                    if (_frameCount == 1 || _frameCount % 60 == 0)
                    {
                        Debug.WriteLine($"[Renderer] 📊 Stats: frames={_frameCount}, totalBytes={_totalBytesWritten >> 20}MB, bitmapNeedsRebind={needNewBitmap}");
                    }
                }
                catch (Exception ex)
                {
                    Debug.WriteLine($"[Renderer] ❌ UpdateFrameTexture error: {ex.Message}\n{ex.StackTrace}");
                }
                finally
                {
                    try { _bitmap.Unlock(); } catch { }
                }

                if (needNewBitmap)
                {
                    BitmapChanged?.Invoke(this, _bitmap);
                }
            }
        }

        public event EventHandler<WriteableBitmap> BitmapChanged;

        public void Render()
        {
        }

        public void Resize(int width, int height)
        {
            lock (_lock)
            {
                if (!IsInitialized || width <= 0 || height <= 0) return;
                if (width != _texWidth || height != _texHeight)
                {
                    _texWidth = width;
                    _texHeight = height;
                    CreateBitmap(width, height);
                    BitmapChanged?.Invoke(this, _bitmap);
                }
            }
        }

        public void Dispose()
        {
            lock (_lock)
            {
                IsInitialized = false;
                _bitmap = null;
            }
        }
    }
}