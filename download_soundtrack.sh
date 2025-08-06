#!/bin/bash

# Download free no-copyright movie soundtrack
# This script downloads a free cinematic soundtrack

echo "Downloading free no-copyright movie soundtrack..."

# Create audio directory if it doesn't exist
mkdir -p priv/static/audio

# Download from Pixabay (free no-copyright music)
# You can replace this URL with any other free movie soundtrack
curl -L "https://cdn.pixabay.com/download/audio/2022/03/15/audio_1647348c4c.mp3?filename=cinematic-background-music-123276.mp3" \
  -o "priv/static/audio/onboarding-background.mp3"

# Alternative: Download from Free Music Archive
# curl -L "https://files.freemusicarchive.org/storage-freemusicarchive-org/music/no_curator/Scott_Holmes/Inspiring_Uplifting_Advertising/Scott_Holmes_-_01_-_Inspiring_Uplifting_Advertising.mp3" \
#   -o "priv/static/audio/onboarding-background.mp3"

echo "Soundtrack downloaded to priv/static/audio/onboarding-background.mp3"
echo "Restart your Phoenix server to use the new soundtrack" 