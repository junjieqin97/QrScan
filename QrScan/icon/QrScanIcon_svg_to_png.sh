#!/bin/bash

# 定义常用 App Icon 尺寸（单位：像素）
sizes=(20 29 40 60 76 83.5 1024)
scales=(1 2 3)

# SVG 文件名
svg_file="QrScanIcon.svg"
# 输出目录，与 SVG 同级
outdir="../Assets.xcassets/AppIcon.appiconset"

for size in "${sizes[@]}"; do
  for scale in "${scales[@]}"; do
    # 计算输出像素实际尺寸
    width=$(echo "$size * $scale" | bc | awk '{printf "%d", $0}')
    height=$width
    # 文件名拼装
    filename="${outdir}/icon_${size}x${size}@${scale}x.png"
    # 生成 PNG
    inkscape --export-type=png "$svg_file" -o "$filename" -w $width -h $height
    echo "生成：$filename"
  done
done

echo "全部尺寸生成完成！"
