#!/bin/bash

echo "Fixing UIKit-related references that should not be themed..."

# Fix UINotificationFeedbackGenerator references
find . -name "*.swift" -type f -exec sed -i '' 's/notificationOccurred(\.themeSuccess)/notificationOccurred(\.success)/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/notificationOccurred(\.themeWarning)/notificationOccurred(\.warning)/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/notificationOccurred(\.themeDanger)/notificationOccurred(\.error)/g' {} \;

# Fix UIImpactFeedbackGenerator references
find . -name "*.swift" -type f -exec sed -i '' 's/UIImpactFeedbackGenerator(style: \.theme/UIImpactFeedbackGenerator(style: \./g' {} \;

# Fix any SFSafariViewController references
find . -name "*.swift" -type f -exec sed -i '' 's/SFSafariViewController(url: url, configuration: \.theme/SFSafariViewController(url: url, configuration: \./g' {} \;

echo "UIKit references fixed!" 