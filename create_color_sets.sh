#!/bin/bash

# Define the base directory for the Assets.xcassets folder
ASSETS_DIR="LogbookOne/Assets.xcassets"

# Create the necessary color sets with light and dark mode variants

# Function to create a color set with light and dark mode colors
create_color_set() {
  local name=$1
  local light_hex=$2
  local dark_hex=$3
  
  # Create the directory
  mkdir -p "$ASSETS_DIR/$name.colorset"
  
  # Generate the Contents.json file with both light and dark variants
  cat > "$ASSETS_DIR/$name.colorset/Contents.json" << EOF
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0x$(echo $light_hex | cut -c 5-6)",
          "green" : "0x$(echo $light_hex | cut -c 3-4)",
          "red" : "0x$(echo $light_hex | cut -c 1-2)"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0x$(echo $dark_hex | cut -c 5-6)",
          "green" : "0x$(echo $dark_hex | cut -c 3-4)",
          "red" : "0x$(echo $dark_hex | cut -c 1-2)"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

  echo "Created $name.colorset"
}

# Create background colors
create_color_set "appBackground" "F5F5F0" "1E1E1E"
create_color_set "cardBackground" "FFFFFF" "2A2A2A"

# Create text colors
create_color_set "primaryText" "2C3E50" "F0F0F0"
create_color_set "secondaryText" "637085" "ABABAB"

# Create accent colors (keep consistent across light/dark)
create_color_set "appAccent" "28C76F" "28C76F"
create_color_set "success" "28C76F" "28C76F"
create_color_set "warning" "FFD580" "FFD580" 
create_color_set "danger" "EA5455" "EA5455"

# Create task type colors (slightly adjusted for dark mode)
create_color_set "taskColor" "4B7BEC" "5B8BFF"
create_color_set "noteColor" "FFA35B" "FFA35B"
create_color_set "paymentColor" "28C76F" "28C76F"

echo "All color sets have been created successfully!" 