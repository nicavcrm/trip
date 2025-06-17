#!/bin/bash

# Production build script for MQTT GeoPath Visualizer

echo "🏗️  Building MQTT GeoPath Visualizer for production..."
echo "=================================================="
echo

# Check if .env exists and has a valid token
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo "Please run ./setup.sh first"
    exit 1
fi

if grep -q "your_mapbox_access_token_here" .env; then
    echo "❌ Error: Mapbox token not configured!"
    echo "Please edit .env and set your actual Mapbox token"
    exit 1
fi

# Check if geo.json exists
if [ ! -f public/geo.json ]; then
    echo "❌ Error: geo.json not found in public/ directory"
    echo "Please run 'cargo run --bin geo' from the main project directory"
    exit 1
fi

echo "✓ Configuration check passed"
echo

# Install dependencies if needed
if [ ! -d node_modules ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

echo "🏗️  Building application..."
npm run build

if [ $? -eq 0 ]; then
    echo
    echo "✅ Build completed successfully!"
    echo "📂 Built files are in the 'dist/' directory"
    echo "🚀 You can now deploy the contents of 'dist/' to your web server"
else
    echo
    echo "❌ Build failed!"
    exit 1
fi
