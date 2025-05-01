#!/bin/bash

if command -v upx >/dev/null 2>&1; then
    echo "UPX is installed"
else
    echo "UPX is not installed"
    exit 1
fi

# Check if packing is enabled via environment variable
if [ "$IS_PACKING_ENABLED" = "true" ]; then
    echo "Packing enabled - processing .so files..."
    # Packing only happens for android
    # Find all .so files in android directory
    find android -name "*.so" | while read -r file; do
        echo "Processing: $file"
        
        # Get original file size
        original_size=$(stat -f %z "$file" 2>/dev/null || stat -c %s "$file")
        
        # Make the .so file executable
        chmod +x "$file"
        
        # # Pack the library using UPX with maximum compression
        upx --ultra-brute --no-lzma "$file" --android-shlib
        
        # Get packed file size
        packed_size=$(stat -f %z "$file" 2>/dev/null || stat -c %s "$file")
        
        # Calculate size reduction
        size_reduction=$((original_size - packed_size))
        reduction_percent=$(awk "BEGIN {printf \"%.2f\", ($size_reduction / $original_size) * 100}")
        
        echo "Size comparison for $file:"
        echo "  Original: $(numfmt --to=iec --suffix=B $original_size)"
        echo "  Packed:   $(numfmt --to=iec --suffix=B $packed_size)"
        echo "  Reduced:  $(numfmt --to=iec --suffix=B $size_reduction) ($reduction_percent%)"
        echo "-------------------"
    done
    
    echo "Packing complete!"
else
    echo "Packing is disabled. Set IS_PACKING_ENABLED=true to enable packing."
fi
