#!/bin/bash

# Create a backup of all Swift files before making changes
echo "Creating backups of all Swift files..."
mkdir -p ./backups
find . -name "*.swift" -type f -exec cp {} ./backups/ \;

# Replace all occurrences of the old color names with the new themed versions
echo "Updating color references in Swift files..."

# Main backgrounds
find . -name "*.swift" -type f -exec sed -i '' 's/Color\.appBackground/Color\.themeBackground/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/Color\.cardBackground/Color\.themeCard/g' {} \;

# Text colors
find . -name "*.swift" -type f -exec sed -i '' 's/Color\.primaryText/Color\.themePrimary/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/Color\.secondaryText/Color\.themeSecondary/g' {} \;

# Accent colors
find . -name "*.swift" -type f -exec sed -i '' 's/Color\.appAccent/Color\.themeAccent/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/Color\.success/Color\.themeSuccess/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/Color\.warning/Color\.themeWarning/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/Color\.danger/Color\.themeDanger/g' {} \;

# Task type colors
find . -name "*.swift" -type f -exec sed -i '' 's/Color\.taskColor/Color\.themeTask/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/Color\.noteColor/Color\.themeNote/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/Color\.paymentColor/Color\.themePayment/g' {} \;

echo "All color references have been updated successfully!" 