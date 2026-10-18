// 冴え 앱 아이콘 생성기 — `swift tools/make-app-icon.swift`로 다시 만든다.
//
// 글꼴을 쓰지 않는다: 시스템 글꼴은 앱 아이콘 사용에 라이선스 제약이 있을 수 있어서, 도형만으로 그린다.
// 모티프는 "초점" — 고리 안의 점. 점은 PVT의 자극, 고리는 거기에 모인 주의를 뜻한다.
// 색은 디자인 토큰과 같다(라이트 #1D6BC7 / 다크 #66B0FA, `Sae/DesignSystem/Theme.swift`).
import AppKit

let size = 1024
let outDir = "Sae/Assets.xcassets/AppIcon.appiconset"

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

/// 한 장을 그린다. `background`가 nil이면 투명(다크·틴트 변형 — 바탕은 시스템이 그린다).
func render(background: CGColor?, mark: CGColor, to name: String) {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        // 바탕이 있는 라이트 아이콘은 **알파 없이**(App Store는 알파 있는 기본 아이콘을 거부한다).
        space: space,
        bitmapInfo: (background == nil ? CGImageAlphaInfo.premultipliedLast : .noneSkipLast).rawValue
    )!
    let s = CGFloat(size)
    if let background {
        ctx.setFillColor(background)
        ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))
    }
    let center = CGPoint(x: s / 2, y: s / 2)

    // 고리
    ctx.setStrokeColor(mark)
    ctx.setLineWidth(s * 0.055)
    let ringRadius = s * 0.30
    ctx.strokeEllipse(in: CGRect(x: center.x - ringRadius, y: center.y - ringRadius,
                                 width: ringRadius * 2, height: ringRadius * 2))
    // 점(자극)
    ctx.setFillColor(mark)
    let dotRadius = s * 0.12
    ctx.fillEllipse(in: CGRect(x: center.x - dotRadius, y: center.y - dotRadius,
                               width: dotRadius * 2, height: dotRadius * 2))

    let image = ctx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: image)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
    print("wrote \(outDir)/\(name)")
}

// 라이트: 브랜드 파랑 바탕 + 흰 마크
render(background: color(0x1D6BC7), mark: color(0xFFFFFF), to: "AppIcon-light.png")
// 다크: 투명 바탕(시스템이 어두운 바탕을 깐다) + 다크 브랜드 색 마크
render(background: nil, mark: color(0x66B0FA), to: "AppIcon-dark.png")
// 틴트: 투명 바탕 + 회색조 마크(시스템이 사용자 색으로 물들인다)
render(background: nil, mark: color(0xFFFFFF), to: "AppIcon-tinted.png")
