#!/bin/bash

# Create images directory if it doesn't exist
mkdir -p priv/static/images

# Icon sizes for PWA
sizes=(72 96 128 144 152 167 180 192 384 512)

echo "Creating placeholder PWA icons..."

for size in "${sizes[@]}"; do
    echo "Creating ${size}x${size} icon..."
    convert -size ${size}x${size} gradient:purple-pink -gravity center -pointsize $(($size/4)) -fill white -annotate 0 "J" priv/static/images/icon-${size}x${size}.png
done

echo "All placeholder icons created successfully!"
echo "Created icons:"
ls -la priv/static/images/icon-*.png 