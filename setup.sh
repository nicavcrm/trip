#!/bin/bash

# Setup script for MQTT GeoPath Visualizer

echo "🗺️  MQTT GeoPath Visualizer Setup"
echo "================================="
echo

# Check if .env exists
if [ -f .env ]; then
    echo "✓ .env file already exists"
else
    echo "📝 Creating .env file..."
    cp .env.example .env 2>/dev/null || echo "VITE_MAPBOX_TOKEN=your_mapbox_access_token_here" > .env
    echo "✓ .env file created"
fi

echo
echo "🔧 Next steps:"
echo "1. Get your Mapbox token from: https://account.mapbox.com/access-tokens/"
echo "2. Edit the .env file and replace 'your_mapbox_access_token_here' with your token"
echo "3. Make sure geo.json exists in the public/ directory (run 'cargo run --bin geo' from the main project)"
echo "4. Run 'npm run dev' to start the development server"
echo
echo "📚 For more information, see README.md"
