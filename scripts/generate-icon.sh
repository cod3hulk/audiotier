#!/bin/bash
# Generates AppIcon.icns from a source PNG image, centered on a square canvas
set -euo pipefail

OUTPUT_DIR="${1:-.}"
SOURCE_IMAGE="${2:-$HOME/Downloads/audiotier-removebg-preview.png}"
ICONSET_DIR=$(mktemp -d)/AppIcon.iconset
mkdir -p "$ICONSET_DIR"

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "==> Source image not found: $SOURCE_IMAGE"
    exit 1
fi

# Use Swift to resize and center on a square white-background canvas
/usr/bin/swift - "$SOURCE_IMAGE" "$ICONSET_DIR" <<'SWIFT'
import AppKit

let sourcePath = CommandLine.arguments[1]
let iconsetDir = CommandLine.arguments[2]

guard let sourceImage = NSImage(contentsOfFile: sourcePath) else {
    fputs("Failed to load source image\n", stderr)
    exit(1)
}

let sizes: [(Int, String)] = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

for (size, filename) in sizes {
    let s = CGFloat(size)
    let img = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()

    // White rounded-rect background
    let bgRect = NSRect(x: 0, y: 0, width: s, height: s)
    let path = NSBezierPath(roundedRect: bgRect, xRadius: s * 0.2, yRadius: s * 0.2)
    NSColor.white.setFill()
    path.fill()

    // Draw source image centered, fitting within the canvas with padding
    let srcW = sourceImage.size.width
    let srcH = sourceImage.size.height
    let padding = s * 0.08
    let available = s - padding * 2
    let scale = min(available / srcW, available / srcH)
    let drawW = srcW * scale
    let drawH = srcH * scale
    let x = (s - drawW) / 2
    let y = (s - drawH) / 2
    sourceImage.draw(in: NSRect(x: x, y: y, width: drawW, height: drawH),
                     from: .zero, operation: .sourceOver, fraction: 1.0)

    img.unlockFocus()

    if let tiff = img.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let url = URL(fileURLWithPath: iconsetDir).appendingPathComponent(filename)
        try! png.write(to: url)
    }
}
SWIFT

# Convert iconset to icns
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_DIR/AppIcon.icns"
echo "==> Icon generated from $SOURCE_IMAGE"

rm -rf "$(dirname "$ICONSET_DIR")"
