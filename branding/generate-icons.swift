// Genera los íconos de Impulso Talker (SVG + PNG) desde una sola definición de geometría.
// Uso: swiftc -O generate-icons.swift -o /tmp/gen-icons && /tmp/gen-icons <carpeta-de-salida>
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

struct RGB {
    let r: Double, g: Double, b: Double, a: Double
    init(_ hex: UInt32, a: Double = 1) {
        r = Double((hex >> 16) & 255) / 255; g = Double((hex >> 8) & 255) / 255
        b = Double(hex & 255) / 255; self.a = a
    }
    var cg: CGColor { CGColor(srgbRed: r, green: g, blue: b, alpha: a) }
    var css: String { String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded())) }
}

// Paleta: azul y marino del diseño de Impulso Creator; amarillo como guiño de chispa.
let marino = RGB(0x111113), amarillo = RGB(0xF2A900)
let amarilloSobreClaro = RGB(0xF2A900), blanco = RGB(0xFFFFFF), bordeClaro = RGB(0xC9D2E0)
// Marca neutra: negro y plata, con el cursor ámbar.
let negro = RGB(0x0B0B0C), plataClara = RGB(0xFFFFFF), plataOscura = RGB(0xB9BCC3), ambar = RGB(0xF2A900)

struct Rect { let x, y, w, h: Double }

// Ícono de app: espacio de 140 x 140. Tres barras de sonido + cursor de texto.
let iconBars = [Rect(x: 20, y: 53, w: 16, h: 34), Rect(x: 50, y: 35, w: 16, h: 70), Rect(x: 80, y: 46, w: 16, h: 48)]
let iconCursor = Rect(x: 114, y: 32, w: 7, h: 76)
// Glifo para la barra de menú / bandeja: espacio de 64 x 64, sin fondo.
let glyphBars = [Rect(x: 7.5, y: 23.5, w: 8, h: 17), Rect(x: 21.5, y: 14.5, w: 8, h: 35), Rect(x: 35.5, y: 20, w: 8, h: 24)]
let glyphCursor = Rect(x: 52.5, y: 13, w: 4, h: 38)

// `barras2`: si existe, las barras llevan un degradado vertical de `barras` (arriba) a `barras2` (abajo): la plata del ícono negro.
struct IconSpec { let nombre: String; let fondo: RGB; let barras: RGB; let cursor: RGB; let borde: RGB?; let cursorSVG: RGB; var barras2: RGB? = nil }

func rr(_ ctx: CGContext, _ r: Rect, _ radius: Double, _ c: RGB) {
    ctx.setFillColor(c.cg)
    ctx.addPath(CGPath(roundedRect: CGRect(x: r.x, y: r.y, width: r.w, height: r.h), cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.fillPath()
}

func bitmap(_ size: Int, _ draw: (CGContext) -> Void) -> CGImage {
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high
    ctx.translateBy(x: 0, y: CGFloat(size)); ctx.scaleBy(x: 1, y: -1)   // y hacia abajo, como SVG
    draw(ctx)
    return ctx.makeImage()!
}

func savePNG(_ img: CGImage, _ url: URL) {
    let d = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, img, nil)
    precondition(CGImageDestinationFinalize(d), "no se pudo escribir \(url.path)")
}

func drawIcon(_ ctx: CGContext, size: Double, margen: Double, spec: IconSpec) {
    let s = size * (1 - 2 * margen) / 140
    ctx.translateBy(x: CGFloat(size * margen), y: CGFloat(size * margen)); ctx.scaleBy(x: CGFloat(s), y: CGFloat(s))
    if let borde = spec.borde {
        rr(ctx, Rect(x: 0, y: 0, w: 140, h: 140), 32, borde)
        rr(ctx, Rect(x: 1.2, y: 1.2, w: 137.6, h: 137.6), 30.8, spec.fondo)
    } else {
        rr(ctx, Rect(x: 0, y: 0, w: 140, h: 140), 32, spec.fondo)
    }
    for b in iconBars {
        if let b2 = spec.barras2 {
            ctx.saveGState()
            ctx.addPath(CGPath(roundedRect: CGRect(x: b.x, y: b.y, width: b.w, height: b.h), cornerWidth: b.w / 2, cornerHeight: b.w / 2, transform: nil))
            ctx.clip()
            let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [spec.barras.cg, b2.cg] as CFArray, locations: [0, 1])!
            ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: b.y), end: CGPoint(x: 0, y: b.y + b.h), options: [])
            ctx.restoreGState()
        } else { rr(ctx, b, b.w / 2, spec.barras) }
    }
    rr(ctx, iconCursor, iconCursor.w / 2, spec.cursor)
}

func drawGlyph(_ ctx: CGContext, size: Double, barras: RGB, cursor: RGB) {
    let s = size * 0.9 / 49
    ctx.translateBy(x: CGFloat(size / 2), y: CGFloat(size / 2)); ctx.scaleBy(x: CGFloat(s), y: CGFloat(s)); ctx.translateBy(x: -32, y: -32)
    for b in glyphBars { rr(ctx, b, b.w / 2, barras) }
    rr(ctx, glyphCursor, glyphCursor.w / 2, cursor)
}

func rectSVG(_ r: Rect, _ radius: Double, _ c: RGB) -> String {
    "<rect x=\"\(r.x)\" y=\"\(r.y)\" width=\"\(r.w)\" height=\"\(r.h)\" rx=\"\(radius)\" fill=\"\(c.css)\"/>"
}

func iconSVG(_ spec: IconSpec) -> String {
    var o = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 140 140\" width=\"512\" height=\"512\">\n<title>Impulso Talker</title>\n"
    if let borde = spec.borde {
        o += rectSVG(Rect(x: 0, y: 0, w: 140, h: 140), 32, borde) + "\n" + rectSVG(Rect(x: 1.2, y: 1.2, w: 137.6, h: 137.6), 30.8, spec.fondo) + "\n"
    } else { o += rectSVG(Rect(x: 0, y: 0, w: 140, h: 140), 32, spec.fondo) + "\n" }
    if let b2 = spec.barras2 {
        o += "<defs><linearGradient id=\"plata\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"\(spec.barras.css)\"/><stop offset=\"1\" stop-color=\"\(b2.css)\"/></linearGradient></defs>\n"
        for b in iconBars { o += "<rect x=\"\(b.x)\" y=\"\(b.y)\" width=\"\(b.w)\" height=\"\(b.h)\" rx=\"\(b.w / 2)\" fill=\"url(#plata)\"/>\n" }
    } else {
        for b in iconBars { o += rectSVG(b, b.w / 2, spec.barras) + "\n" }
    }
    o += rectSVG(iconCursor, iconCursor.w / 2, spec.cursor) + "\n</svg>\n"
    return o
}

func glyphSVG(_ c: RGB) -> String {
    var o = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 64 64\" width=\"64\" height=\"64\">\n<title>Impulso Talker (monocromático)</title>\n"
    for b in glyphBars { o += rectSVG(b, b.w / 2, c) + "\n" }
    o += rectSVG(glyphCursor, glyphCursor.w / 2, c) + "\n</svg>\n"
    return o
}

// Íconos de bandeja con estados (64 x 64): reposo, grabando, transcribiendo y aviso.
// Son los mismos nombres de archivo que usa Handy en src-tauri/resources.
enum TrayState { case idle, recording, transcribing, warning }

func clearCircle(_ ctx: CGContext, _ cx: Double, _ cy: Double, _ r: Double) {
    ctx.saveGState(); ctx.setBlendMode(.clear)
    ctx.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)); ctx.restoreGState()
}
func fillCircle(_ ctx: CGContext, _ cx: Double, _ cy: Double, _ r: Double, _ c: RGB) {
    ctx.setFillColor(c.cg); ctx.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
}
func glyph(_ ctx: CGContext, scale: Double, cx: Double, cy: Double, bars: RGB, cursor: RGB, clear: Bool) {
    ctx.saveGState()
    if clear { ctx.setBlendMode(.clear) }
    ctx.translateBy(x: CGFloat(cx), y: CGFloat(cy)); ctx.scaleBy(x: CGFloat(scale), y: CGFloat(scale)); ctx.translateBy(x: -32, y: -32)
    for b in glyphBars { rr(ctx, b, b.w / 2, bars) }
    rr(ctx, glyphCursor, glyphCursor.w / 2, cursor)
    ctx.restoreGState()
}
func trayImage(_ state: TrayState, bars: RGB, cursor: RGB) -> CGImage {
    bitmap(64) { ctx in
        switch state {
        case .idle:
            glyph(ctx, scale: 1.15, cx: 32, cy: 32, bars: bars, cursor: cursor, clear: false)
        case .recording:
            fillCircle(ctx, 32, 32, 30, bars)
            glyph(ctx, scale: 0.72, cx: 32, cy: 32, bars: blanco, cursor: blanco, clear: true)
        case .transcribing:
            fillCircle(ctx, 32, 32, 30, bars)
            for x in [19.0, 32.0, 45.0] { clearCircle(ctx, x, 32, 4.6) }
        case .warning:
            glyph(ctx, scale: 0.95, cx: 28, cy: 27, bars: bars, cursor: cursor, clear: false)
            clearCircle(ctx, 47, 47, 16.5)
            fillCircle(ctx, 47, 47, 13.5, bars)
            ctx.saveGState(); ctx.setBlendMode(.clear)
            ctx.addPath(CGPath(roundedRect: CGRect(x: 44.9, y: 39.5, width: 4.2, height: 10), cornerWidth: 2.1, cornerHeight: 2.1, transform: nil)); ctx.fillPath()
            ctx.fillEllipse(in: CGRect(x: 44.8, y: 51.8, width: 4.4, height: 4.4)); ctx.restoreGState()
        }
    }
}
func writeTray(to dir: URL) {
    let names: [(TrayState, String)] = [(.idle, "idle"), (.recording, "recording"), (.transcribing, "transcribing")]
    let claro = blanco, oscuro = RGB(0x1A1A1A), color = RGB(0x6B6E76)
    for (state, n) in names {
        savePNG(trayImage(state, bars: claro, cursor: claro), dir.appendingPathComponent("tray_\(n).png"))
        savePNG(trayImage(state, bars: oscuro, cursor: oscuro), dir.appendingPathComponent("tray_\(n)_dark.png"))
    }
    savePNG(trayImage(.warning, bars: claro, cursor: claro), dir.appendingPathComponent("tray_idle_warning.png"))
    savePNG(trayImage(.warning, bars: oscuro, cursor: oscuro), dir.appendingPathComponent("tray_idle_warning_dark.png"))
    // Tema «colorido»: grafito con el cursor ámbar
    let amarilloSolido = RGB(0xF2A900)
    savePNG(trayImage(.idle, bars: color, cursor: amarilloSolido), dir.appendingPathComponent("handy.png"))
    savePNG(trayImage(.recording, bars: color, cursor: color), dir.appendingPathComponent("recording.png"))
    savePNG(trayImage(.transcribing, bars: color, cursor: color), dir.appendingPathComponent("transcribing.png"))
    savePNG(trayImage(.warning, bars: color, cursor: amarilloSolido), dir.appendingPathComponent("handy_warning.png"))
}

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
func write(_ s: String, _ n: String) { try! s.write(to: out.appendingPathComponent(n), atomically: true, encoding: .utf8) }

let specs = [
    // El ícono principal: negro con barras de plata y cursor ámbar.
    IconSpec(nombre: "negro", fondo: negro, barras: plataClara, cursor: ambar, borde: nil, cursorSVG: ambar, barras2: plataOscura),
    // Para fondos oscuros del sitio o de documentos que piden una versión clara.
    IconSpec(nombre: "claro", fondo: RGB(0xFFFFFF), barras: RGB(0x155EEF), cursor: ambar, borde: RGB(0xE1E4EA), cursorSVG: ambar),
]
for spec in specs {
    write(iconSVG(spec), "icon-\(spec.nombre).svg")
    // 1024 con el margen transparente de las plantillas de macOS (100 px por lado)
    savePNG(bitmap(1024) { drawIcon($0, size: 1024, margen: 100.0 / 1024, spec: spec) }, out.appendingPathComponent("icon-\(spec.nombre)-1024.png"))
}

// Barra de menú de macOS: plantilla negra con transparencia (el sistema la tiñe).
write(glyphSVG(RGB(0x000000)), "tray-template.svg")
savePNG(bitmap(44) { drawGlyph($0, size: 44, barras: RGB(0x000000), cursor: RGB(0x000000)) }, out.appendingPathComponent("tray-template@2x.png"))
savePNG(bitmap(22) { drawGlyph($0, size: 22, barras: RGB(0x000000), cursor: RGB(0x000000)) }, out.appendingPathComponent("tray-template.png"))
// Bandeja de Windows: versión blanca (barra oscura) y negra (barra clara), con el cursor amarillo.
savePNG(bitmap(64) { drawGlyph($0, size: 64, barras: blanco, cursor: amarillo) }, out.appendingPathComponent("tray-windows-oscuro.png"))
savePNG(bitmap(64) { drawGlyph($0, size: 64, barras: marino, cursor: amarilloSobreClaro) }, out.appendingPathComponent("tray-windows-claro.png"))
if CommandLine.arguments.count > 2 { writeTray(to: URL(fileURLWithPath: CommandLine.arguments[2])); print("íconos de bandeja en \(CommandLine.arguments[2])") }
print("listo en \(out.path)")
