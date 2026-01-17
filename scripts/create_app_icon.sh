#!/bin/bash
#
# Create an app icon for Shortcut Detective
# Uses Python with Pillow to generate a modern icon
#

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICONS_DIR="$PROJECT_DIR/icons"
ICONSET_DIR="$ICONS_DIR/AppIcon.iconset"

echo "=================================================="
echo "Creating Shortcut Detective App Icon"
echo "=================================================="
echo ""

# Create icons directory
mkdir -p "$ICONS_DIR"
mkdir -p "$ICONSET_DIR"

# Check if Python with PIL/Pillow is available
if python3 -c "from PIL import Image, ImageDraw, ImageFont" 2>/dev/null; then
    echo "Using Python + Pillow to generate icon..."

    python3 - "$PROJECT_DIR" << 'PYTHON_EOF'
from PIL import Image, ImageDraw, ImageFont
import os
import sys

PROJECT_DIR = sys.argv[1]
ICONS_DIR = os.path.join(PROJECT_DIR, "icons")
ICONSET_DIR = os.path.join(ICONS_DIR, "AppIcon.iconset")

# Ensure directories exist
os.makedirs(ICONSET_DIR, exist_ok=True)

def create_icon(size):
    """Create a magnifying glass icon for Shortcut Detective"""
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Colors
    bg_color = (45, 52, 64, 255)       # Dark blue-gray background
    glass_color = (255, 255, 255, 255)  # White magnifying glass
    lens_color = (100, 180, 255, 255)   # Light blue lens
    handle_color = (200, 200, 200, 255) # Gray handle
    key_color = (255, 200, 50, 255)     # Gold key/shortcut indicator

    padding = size // 8

    # Draw rounded rectangle background
    corner_radius = size // 5
    draw.rounded_rectangle(
        [padding//2, padding//2, size - padding//2, size - padding//2],
        radius=corner_radius,
        fill=bg_color
    )

    # Magnifying glass dimensions
    center_x = size // 2 - size // 10
    center_y = size // 2 - size // 10
    glass_radius = size // 4
    handle_length = size // 3
    handle_width = size // 12

    # Draw lens (circle with blue fill)
    draw.ellipse(
        [center_x - glass_radius, center_y - glass_radius,
         center_x + glass_radius, center_y + glass_radius],
        fill=lens_color,
        outline=glass_color,
        width=max(2, size // 40)
    )

    # Draw handle (diagonal line)
    handle_start_x = center_x + int(glass_radius * 0.7)
    handle_start_y = center_y + int(glass_radius * 0.7)
    handle_end_x = handle_start_x + int(handle_length * 0.7)
    handle_end_y = handle_start_y + int(handle_length * 0.7)

    draw.line(
        [handle_start_x, handle_start_y, handle_end_x, handle_end_y],
        fill=handle_color,
        width=handle_width
    )

    # Draw keyboard shortcut symbol (⌘) inside the lens
    # Use a simple representation: small squares in a pattern
    symbol_size = size // 20
    symbol_offset = size // 15

    # Draw a simple "Cmd" style symbol
    for dx, dy in [(-1, -1), (-1, 1), (1, -1), (1, 1)]:
        x = center_x + dx * symbol_offset
        y = center_y + dy * symbol_offset
        draw.ellipse(
            [x - symbol_size, y - symbol_size, x + symbol_size, y + symbol_size],
            fill=key_color
        )

    # Connect the circles with lines
    line_width = max(2, size // 50)
    draw.line([center_x - symbol_offset, center_y - symbol_offset,
               center_x - symbol_offset, center_y + symbol_offset],
              fill=key_color, width=line_width)
    draw.line([center_x + symbol_offset, center_y - symbol_offset,
               center_x + symbol_offset, center_y + symbol_offset],
              fill=key_color, width=line_width)
    draw.line([center_x - symbol_offset, center_y - symbol_offset,
               center_x + symbol_offset, center_y - symbol_offset],
              fill=key_color, width=line_width)
    draw.line([center_x - symbol_offset, center_y + symbol_offset,
               center_x + symbol_offset, center_y + symbol_offset],
              fill=key_color, width=line_width)

    return img

# Generate icons for all required sizes
icon_sizes = [16, 32, 64, 128, 256, 512, 1024]

for size in icon_sizes:
    img = create_icon(size)

    # Save standard resolution
    if size <= 512:
        img.save(os.path.join(ICONSET_DIR, f"icon_{size}x{size}.png"))

    # Save @2x resolution
    if size >= 32:
        half_size = size // 2
        if half_size in [16, 32, 128, 256, 512]:
            img.save(os.path.join(ICONSET_DIR, f"icon_{half_size}x{half_size}@2x.png"))

# Also save the largest as a master PNG
master = create_icon(1024)
master.save(os.path.join(ICONS_DIR, "AppIcon.png"))

print("✓ Icon PNGs generated successfully")
PYTHON_EOF

else
    echo "Pillow not found, creating basic icon using sips..."

    # Create a simple colored square as fallback
    # This is very basic but works without dependencies

    # Create a basic 1024x1024 PNG using macOS built-in tools
    python3 << 'PYTHON_EOF'
# Fallback using only standard library
import subprocess
import os

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONS_DIR = os.path.join(PROJECT_DIR, "icons")
ICONSET_DIR = os.path.join(ICONS_DIR, "AppIcon.iconset")

os.makedirs(ICONSET_DIR, exist_ok=True)

# Create a simple PPM image (no dependencies needed)
def create_ppm_icon(size, filename):
    with open(filename, 'wb') as f:
        f.write(f"P6\n{size} {size}\n255\n".encode())
        for y in range(size):
            for x in range(size):
                # Dark blue background with lighter center (magnifying glass style)
                cx, cy = size // 2, size // 2
                dist = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                if dist < size // 3:
                    # Light blue center
                    f.write(bytes([100, 180, 255]))
                else:
                    # Dark blue-gray background
                    f.write(bytes([45, 52, 64]))

# Generate icons
for size in [16, 32, 128, 256, 512]:
    ppm_file = os.path.join(ICONSET_DIR, f"icon_{size}x{size}.ppm")
    png_file = os.path.join(ICONSET_DIR, f"icon_{size}x{size}.png")
    create_ppm_icon(size, ppm_file)
    subprocess.run(['sips', '-s', 'format', 'png', ppm_file, '--out', png_file],
                   capture_output=True)
    os.remove(ppm_file)

    # Also create @2x versions
    if size <= 256:
        double_size = size * 2
        ppm_file = os.path.join(ICONSET_DIR, f"icon_{size}x{size}@2x.ppm")
        png_file = os.path.join(ICONSET_DIR, f"icon_{size}x{size}@2x.png")
        create_ppm_icon(double_size, ppm_file)
        subprocess.run(['sips', '-s', 'format', 'png', ppm_file, '--out', png_file],
                       capture_output=True)
        os.remove(ppm_file)

print("✓ Basic icon PNGs generated")
PYTHON_EOF
fi

# Convert iconset to icns using macOS iconutil
echo ""
echo "Converting to .icns format..."
if [ -d "$ICONSET_DIR" ]; then
    iconutil -c icns "$ICONSET_DIR" -o "$ICONS_DIR/AppIcon.icns"
    echo "✓ AppIcon.icns created successfully"
else
    echo "❌ Error: iconset directory not found"
    exit 1
fi

# Clean up iconset directory (optional, keep for debugging)
# rm -rf "$ICONSET_DIR"

echo ""
echo "=================================================="
echo "✓ App icon created successfully!"
echo "=================================================="
echo ""
echo "Icon location: $ICONS_DIR/AppIcon.icns"
echo ""
