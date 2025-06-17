#!/bin/bash

# Simple GitHub Pages deployment using gh-pages branch

set -e

echo "🚀 Deploying to GitHub Pages..."
echo "================================"
echo

# Check if dist directory exists
if [ ! -d "dist" ]; then
    echo "❌ Error: dist directory not found!"
    echo "Please run './build.sh' first"
    exit 1
fi

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository!"
    echo "Please initialize git first: git init"
    exit 1
fi

# Check if there's a remote repository
if ! git remote get-url origin >/dev/null 2>&1; then
    echo "❌ Error: No remote repository configured!"
    echo "Please add a remote repository first:"
    echo "git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
    exit 1
fi

# Get current branch and commit
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT=$(git rev-parse --short HEAD)

echo "📋 Current branch: $CURRENT_BRANCH"
echo "📋 Current commit: $CURRENT_COMMIT"
echo "📋 Remote: $(git remote get-url origin)"
echo

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
echo "📁 Using temporary directory: $TEMP_DIR"

# Copy dist files to temp directory
cp -r dist/* "$TEMP_DIR/"

# Create .nojekyll file
touch "$TEMP_DIR/.nojekyll"

# Initialize git in temp directory
cd "$TEMP_DIR"
git init
git add .
git commit -m "Deploy from $CURRENT_BRANCH@$CURRENT_COMMIT"

# Add remote and push to gh-pages branch
git remote add origin "$(cd - >/dev/null && git remote get-url origin)"
git branch -M gh-pages
git push -f origin gh-pages

cd - >/dev/null
rm -rf "$TEMP_DIR"

echo
echo "✅ Successfully deployed to GitHub Pages!"
echo
echo "🌐 Your site will be available at:"
echo "   https://YOUR_USERNAME.github.io/YOUR_REPO"
echo
echo "📋 Next steps:"
echo "   1. Go to your repository on GitHub"
echo "   2. Go to Settings → Pages"
echo "   3. Under 'Source', select 'Deploy from a branch'"
echo "   4. Select 'gh-pages' branch and '/ (root)' folder"
echo "   5. Click 'Save'"
echo "   6. Wait a few minutes for the site to be live"
