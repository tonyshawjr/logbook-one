#!/bin/bash

# This script updates all remaining color references to use the theme-prefixed names

echo "Updating remaining color references..."

# Find and replace all remaining references
find . -name "*.swift" -type f -exec sed -i '' 's/\.primaryText/\.themePrimary/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\.secondaryText/\.themeSecondary/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\.appAccent/\.themeAccent/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\.paymentColor/\.themePayment/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\.taskColor/\.themeTask/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\.noteColor/\.themeNote/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\.appBackground/\.themeBackground/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\.cardBackground/\.themeCard/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\.success/\.themeSuccess/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\.warning/\.themeWarning/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\.danger/\.themeDanger/g' {} \;

# Skip backup files to avoid duplicate updates
find ./LogbookOne -name "*.swift" -type f -exec sed -i '' 's/\.primaryText/\.themePrimary/g' {} \;
find ./LogbookOne -name "*.swift" -type f -exec sed -i '' 's/\.secondaryText/\.themeSecondary/g' {} \;
find ./LogbookOne -name "*.swift" -type f -exec sed -i '' 's/\.appAccent/\.themeAccent/g' {} \;
find ./LogbookOne -name "*.swift" -type f -exec sed -i '' 's/\.paymentColor/\.themePayment/g' {} \;
find ./LogbookOne -name "*.swift" -type f -exec sed -i '' 's/\.taskColor/\.themeTask/g' {} \;
find ./LogbookOne -name "*.swift" -type f -exec sed -i '' 's/\.noteColor/\.themeNote/g' {} \;

echo "All remaining color references have been updated!" 