#!/bin/bash

# JetBrains IDE Trial Reset Script
# Enhanced version with better error handling and additional cleanup

# https://gist.github.com/h3ssan/9510fbb2291d41b090cf52adb2edd1c4
# https://gist.github.com/mnabila/f606fdfe120c5c53f762c08e46be0554

products=("IntelliJIdea" "WebStorm" "DataGrip" "PhpStorm" "CLion" "PyCharm" "GoLand" "RubyMine")

echo "=== JetBrains IDE Trial Reset ==="
echo

for product in "${products[@]}"; do
    echo "[+] Resetting trial period for $product"
    
    # Remove evaluation files from both possible locations
    eval_paths=(
        "$HOME/.config/$product"*/eval
        "$HOME/.config/JetBrains/$product"*/eval
        "$HOME/.$product"*/config/eval"  # Some versions use this path
    )
    
    for path in "${eval_paths[@]}"; do
        if [ -d "$path" ] || [ -f "$path" ]; then
            rm -rf "$path" 2>/dev/null && echo "  Removed: $path"
        fi
    done
    
    # Clean evlsprt properties from XML files
    xml_paths=(
        "$HOME/.config/$product"*/options/other.xml
        "$HOME/.config/JetBrains/$product"*/options/other.xml
        "$HOME/.$product"*/config/options/other.xml
    )
    
    for xml_file in "${xml_paths[@]}"; do
        if [ -f "$xml_file" ]; then
            if grep -q "evlsprt" "$xml_file" 2>/dev/null; then
                sed -i.bak '/evlsprt/d' "$xml_file" 2>/dev/null
                echo "  Cleaned: $xml_file"
                # Remove backup file if created
                [ -f "${xml_file}.bak" ] && rm "${xml_file}.bak"
            fi
        fi
    done
    
    echo
done

# Additional cleanup
echo "[+] Removing user preferences and cache files..."
rm -rf ~/.java/.userPrefs 2>/dev/null && echo "  Removed Java user preferences"

# Additional cache directories that might store trial info
cache_paths=(
    "$HOME/.cache/JetBrains"
    "$HOME/.local/share/JetBrains"
)

for cache_path in "${cache_paths[@]}"; do
    if [ -d "$cache_path" ]; then
        find "$cache_path" -name "*eval*" -exec rm -rf {} \; 2>/dev/null
        echo "  Cleaned eval files from: $cache_path"
    fi
done

echo
echo "=== Reset complete! ==="
echo "Note: You may need to delete the IDE's internal caches through:"
echo "      File > Invalidate Caches / Restart > Invalidate and Restart"
