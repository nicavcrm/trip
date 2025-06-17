#!/bin/bash

# GitHub Pages deployment script for MQTT GeoPath Visualizer

set -e  # Exit on any error

echo "🚀 Deploying MQTT GeoPath Visualizer to GitHub Pages..."
echo "======================================================"
echo

# Configuration - Edit these variables
GITHUB_USERNAME="nicavcrm"  # Replace with your GitHub username
REPO_NAME="demo"                    # Name for the GitHub Pages repository
COMMIT_MESSAGE="Deploy $(date '+%Y-%m-%d %H:%M:%S')"

echo "📋 Configuration:"
echo "   GitHub Username: $GITHUB_USERNAME"
echo "   Repository Name: $REPO_NAME"
echo "   GitHub Pages URL will be: https://$GITHUB_USERNAME.github.io/$REPO_NAME"
echo

# Check if dist directory exists
if [ ! -d "dist" ]; then
    echo "❌ Error: dist directory not found!"
    echo "Please run './build.sh' first to create the production build"
    exit 1
fi

# Check if GitHub username is configured
if [ "$GITHUB_USERNAME" = "your-github-username" ]; then
    echo "❌ Error: Please edit this script and set your actual GitHub username"
    echo "Edit the GITHUB_USERNAME variable at the top of this script"
    exit 1
fi

# Create a temporary directory for the GitHub Pages repository
TEMP_DIR=$(mktemp -d)
echo "📁 Created temporary directory: $TEMP_DIR"

# Clone or create the GitHub Pages repository
REPO_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
echo "🔄 Setting up repository..."

if git ls-remote "$REPO_URL" &>/dev/null; then
    echo "   Repository exists, cloning..."
    git clone "$REPO_URL" "$TEMP_DIR"
else
    echo "   Repository doesn't exist, creating new one..."
    cd "$TEMP_DIR"
    git init
    git remote add origin "$REPO_URL"

    # Create initial README
    cat > README.md << EOF
# MQTT GeoPath Visualizer

This repository contains the deployed UI for the MQTT GeoPath Visualizer.

🌐 **Live Demo**: https://$GITHUB_USERNAME.github.io/$REPO_NAME

## About

This is an interactive web application that visualizes MQTT message data on a map, showing GPS coordinates as connected paths over time.

## Features

- Real-time GPS coordinate visualization
- Interactive map with Mapbox GL
- GeoJSON data rendering
- Responsive design

## Technology Stack

- Vue.js 3
- Vite
- Mapbox GL JS
- Built from Rust MQTT data processing

---

*Deployed automatically from the main project repository*
EOF

    git add README.md
    git commit -m "Initial commit"
fi

cd "$TEMP_DIR"

# Clear existing files (except .git and README.md)
find . -maxdepth 1 ! -name '.' ! -name '..' ! -name '.git' ! -name 'README.md' -exec rm -rf {} +

# Copy dist files
echo "📦 Copying built files..."
cp -r "$OLDPWD/dist/"* .

# Create .nojekyll file to bypass Jekyll processing
touch .nojekyll

# Create CNAME file if custom domain is needed (commented out by default)
# echo "your-domain.com" > CNAME

# Add all files
git add .

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo "ℹ️  No changes to deploy"
else
    echo "📝 Committing changes..."
    git commit -m "$COMMIT_MESSAGE"

    echo "⬆️  Pushing to GitHub..."
    git push -u origin main

    echo
    echo "✅ Deployment completed successfully!"
    echo
    echo "🌐 Your site will be available at:"
    echo "   https://$GITHUB_USERNAME.github.io/$REPO_NAME"
    echo
    echo "📋 Next steps:"
    echo "   1. Go to https://github.com/$GITHUB_USERNAME/$REPO_NAME"
    echo "   2. Go to Settings → Pages"
    echo "   3. Under 'Source', select 'Deploy from a branch'"
    echo "   4. Select 'main' branch and '/ (root)' folder"
    echo "   5. Click 'Save'"
    echo "   6. Wait a few minutes for the site to be live"
fi

# Cleanup
cd "$OLDPWD"
rm -rf "$TEMP_DIR"
echo "🧹 Cleaned up temporary files"
