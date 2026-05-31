#!/usr/bin/swift
// ASMR app icon — 1024×1024
// "#" drawn geometrically with correct typographic proportions.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let side = 1024
let W = CGFloat(side), H = CGFloat(side)

guard let ctx = CGContext(data: nil, width: side, height: side,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGBitmapInfo(rawValue:
        CGImageAlphaInfo.premultipliedFirst.rawValue |
        CGBitmapInfo.byteOrder32Little.rawValue).rawValue)
else { exit(1) }

// ── Background ────────────────────────────────────────────────────────────
ctx.setFillColor(CGColor(red: 0.110, green: 0.110, blue: 0.118, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

if let grad = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [CGColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 0.45),
             CGColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 0.00)] as CFArray,
    locations: [0.0, 1.0]) {
    ctx.drawRadialGradient(grad,
        startCenter: CGPoint(x: W*0.5, y: H*0.5), startRadius: 0,
        endCenter:   CGPoint(x: W*0.5, y: H*0.5), endRadius: W*0.65, options: [])
}

// ── "#" geometry ─────────────────────────────────────────────────────────
// A correct "#" has two close-set vertical strokes and two horizontal bars
// that extend noticeably past the strokes on both sides.
//
// Reference proportions from a bold condensed typeface:
//   - Symbol is roughly square.
//   - Stroke width  ≈ 13% of symbol size.
//   - Stroke centers are ~35% apart (relative to symbol width).
//   - Bars overhang the outer stroke edges by ~13% of symbol size.
//   - Upper bar sits at 37% down; lower bar at 63% down.

ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))

let symSize: CGFloat = 590            // symbol fits inside 590×590
let ox = (W - symSize) / 2            // left edge of symbol box
let oy = (H - symSize) / 2            // bottom edge (CG: y=0 is bottom)

let sw: CGFloat  = symSize * 0.130    // stroke width  ≈ 77 px
let bh: CGFloat  = symSize * 0.118    // bar height    ≈ 70 px
let oh: CGFloat  = symSize * 0.130    // bar overhang past outer stroke edge

// Stroke centres (x), relative to canvas
let lx = ox + symSize * 0.330         // left stroke centre-x
let rx = ox + symSize * 0.670         // right stroke centre-x

// Full vertical extent of strokes (± a touch past bar region)
let vTop    = oy - symSize * 0.04
let vBottom = oy + symSize + symSize * 0.04

// Draw vertical strokes
ctx.fill(CGRect(x: lx - sw/2, y: vTop, width: sw, height: vBottom - vTop))
ctx.fill(CGRect(x: rx - sw/2, y: vTop, width: sw, height: vBottom - vTop))

// Bar horizontal extent: from past left-stroke's left edge to past right-stroke's right
let barL = lx - sw/2 - oh
let barR = rx + sw/2 + oh

// Upper bar centre-y (CG): 37% down from top = 63% up from bottom of symbol
let ucy = oy + symSize * 0.630
let lcy = oy + symSize * 0.370

ctx.fill(CGRect(x: barL, y: ucy - bh/2, width: barR - barL, height: bh))
ctx.fill(CGRect(x: barL, y: lcy - bh/2, width: barR - barL, height: bh))

// ── Write PNG ─────────────────────────────────────────────────────────────
guard let img = ctx.makeImage() else { exit(1) }
let url = URL(fileURLWithPath: "/tmp/asmr_icon_1024.png")
let dst = CGImageDestinationCreateWithURL(url as CFURL,
          UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dst, img, nil)
guard CGImageDestinationFinalize(dst) else { exit(1) }
print("✓ \(url.path)")
