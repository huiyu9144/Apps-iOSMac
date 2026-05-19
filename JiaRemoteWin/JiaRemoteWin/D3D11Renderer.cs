using System;
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

        public bool IsInitialized { get; private set; }
        public WriteableBitmap Bitmap => _bitmap;

        public void Initialize(int width, int height)
        {
            lock (_lock)
            {
                _texWidth = width > 0 ? width : 1920;
                _texHeight = height > 0 ? height : 1080;

                _bitmap = new WriteableBitmap(
                    _texWidth, _texHeight,
                    96, 96,
                    PixelFormats.Bgra32,
                    null);

                IsInitialized = true;
                System.Diagnostics.Debug.WriteLine($"[Renderer] Initialized {_texWidth}x{_texHeight}");
            }
        }

        public void UpdateFrameTexture(byte[] pixelData, uint width, uint height, uint bytesPerRow)
        {
            lock (_lock)
            {
                if (!IsInitialized) return;

                int w = (int)width;
                int h = (int)height;

                if (_bitmap == null || w != _texWidth || h != _texHeight)
                {
                    _texWidth = w;
                    _texHeight = h;
                    _bitmap = new WriteableBitmap(w, h, 96, 96, PixelFormats.Bgra32, null);
                }

                try
                {
                    _bitmap.Lock();

                    int srcStride = (int)bytesPerRow;
                    int dstStride = _bitmap.BackBufferStride;

                    if (srcStride == dstStride)
                    {
                        System.Runtime.InteropServices.Marshal.Copy(
                            pixelData, 0,
                            _bitmap.BackBuffer,
                            Math.Min(pixelData.Length, h * dstStride));
                    }
                    else
                    {
                        int copyBytes = Math.Min(srcStride, dstStride);
                        unsafe
                        {
                            byte* dstPtr = (byte*)_bitmap.BackBuffer.ToPointer();
                            fixed (byte* srcPtr = pixelData)
                            {
                                for (int y = 0; y < h; y++)
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
                    }

                    _bitmap.AddDirtyRect(new Int32Rect(0, 0, w, h));
                }
                finally
                {
                    _bitmap.Unlock();
                }
            }
        }

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
                    _bitmap = new WriteableBitmap(width, height, 96, 96, PixelFormats.Bgra32, null);
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