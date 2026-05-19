from PIL import Image
import os

base_dir = r"c:/Users/Administrator/Desktop/111111/jia-ios/MenuTimer/MenuTimer/Assets.xcassets/AppIcon.appiconset"
input_path = os.path.join(base_dir, "icon_1024.png")

if not os.path.exists(input_path):
    print("❌ 找不到 icon_1024.png")
    exit(1)

img = Image.open(input_path)

sizes = [
    ("icon_16.png", 16),
    ("icon_32.png", 32),
    ("icon_64.png", 64),
    ("icon_128.png", 128),
    ("icon_256.png", 256),
    ("icon_512.png", 512),
    ("icon_1024.png", 1024),
]

for filename, size in sizes:
    output_path = os.path.join(base_dir, filename)
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(output_path, "PNG")
    print(f"✅ 已生成 {filename} ({size}x{size})")

# 更新Contents.json为完整配置
contents_json = {
  "images" : [
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16",
      "filename" : "icon_16.png"
    },
    {
      "idiom" : "