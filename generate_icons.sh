#!/bin/bash

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "ImageMagick is not installed. Please install it first:"
    echo "sudo apt-get install imagemagick"
    exit 1
fi

# Create images directory if it doesn't exist
mkdir -p priv/static/images

# Icon sizes for PWA
sizes=(72 96 128 144 152 167 180 192 384 512)

echo "Generating PWA icons..."

for size in "${sizes[@]}"; do
    echo "Generating ${size}x${size} icon..."
    convert priv/static/images/icon.svg -resize ${size}x${size} priv/static/images/icon-${size}x${size}.png
done

echo "All icons generated successfully!"
echo "Generated icons:"
ls -la priv/static/images/icon-*.png 