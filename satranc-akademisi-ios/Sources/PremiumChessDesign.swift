import SwiftUI
import UIKit

/// Shared navy/bronze design language. All icons are chess-piece glyphs
/// rendered locally as vectors/text: no internet, stock photos or permissions.
extension Theme {
    static let midnight = Color(red: 0.024, green: 0.050, blue: 0.095)
    static let deepBlue = Color(red: 0.055, green: 0.115, blue: 0.180)
    static let raised = Color(red: 0.095, green: 0.174, blue: 0.242)
    static let border = Color(red: 0.30, green: 0.37, blue: 0.42)
    static let champagne = Color(red: 1.0, green: 0.87, blue: 0.65)
    static let pale = Color(red: 0.80, green: 0.85, blue: 0.87)
    static let ink = Color(red: 0.13, green: 0.13, blue: 0.16)
    static let warmGreen = Color(red: 0.48, green: 0.83, blue: 0.62)
    static let metal = LinearGradient(
        colors: [champagne, gold, Color(red: 0.63, green: 0.43, blue: 0.24)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let night = LinearGradient(
        colors: [Color(red: 0.105, green: 0.20, blue: 0.29), midnight],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

enum PremiumChessPiece: String {
    case king, queen, rook, bishop, knight, pawn
    var glyph: String {
        switch self {
        case .king: return "♚"
        case .queen: return "♛"
        case .rook: return "♜"
        case .bishop: return "♝"
        case .knight: return "♞"
        case .pawn: return "♟︎"
        }
    }
    var name: String {
        switch self {
        case .king: return "Şah"
        case .queen: return "Vezir"
        case .rook: return "Kale"
        case .bishop: return "Fil"
        case .knight: return "At"
        case .pawn: return "Piyon"
        }
    }
}

/// Always-template UIKit glyphs preserve native TabView behaviour and VoiceOver
/// while actually resembling chess pieces instead of generic app symbols.
enum ChessTabArt {
    static func image(for piece: PremiumChessPiece) -> UIImage {
        let size = CGSize(width: 34, height: 34)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 3
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let img = renderer.image { _ in
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            (piece.glyph as NSString).draw(
                in: CGRect(x: 0, y: -2, width: 34, height: 36),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 30, weight: .regular),
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: paragraph
                ]
            )
        }
        return img.withRenderingMode(.alwaysTemplate)
    }
}

struct PremiumBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Theme.night
                Circle()
                    .fill(Theme.gold.opacity(0.12))
                    .frame(width: 330, height: 330)
                    .blur(radius: 90)
                    .position(x: geometry.size.width * 0.9, y: 90)
                Circle()
                    .fill(Color(red: 0.10, green: 0.32, blue: 0.39).opacity(0.4))
                    .frame(width: 350, height: 350)
                    .blur(radius: 95)
                    .position(x: 20, y: geometry.size.height * 0.7)
                Text("♞")
                    .font(.system(size: 280, weight: .thin))
                    .foregroundStyle(Theme.champagne.opacity(0.035))
                    .rotationEffect(.degrees(-16))
                    .position(x: geometry.size.width * 0.83, y: geometry.size.height * 0.48)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ChessPieceBadge: View {
    let piece: PremiumChessPiece
    var size: CGFloat = 56
    var highlighted: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27)
                .fill(
                    highlighted
                    ? LinearGradient(
                        colors: [Theme.gold.opacity(0.38), Theme.gold.opacity(0.07)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Theme.raised, Theme.midnight],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: size * 0.27)
                .stroke(Theme.gold.opacity(highlighted ? 0.7 : 0.27), lineWidth: 1)
            Text(piece.glyph)
                .font(.system(size: size * 0.62, weight: .regular, design: .serif))
                .foregroundStyle(Theme.metal)
                .shadow(color: Theme.gold.opacity(0.28), radius: 6, y: 2)
                .minimumScaleFactor(0.6)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(piece.name)
    }
}

struct PremiumPanel<Content: View>: View {
    var accent: Bool = false
    var padding: CGFloat = 17
    let content: Content

    init(accent: Bool = false, padding: CGFloat = 17,
         @ViewBuilder content: () -> Content) {
        self.accent = accent
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [
                                accent ? Theme.gold.opacity(0.16) : Theme.raised.opacity(0.9),
                                Theme.midnight.opacity(0.96)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                LinearGradient(
                                    colors: [Theme.gold.opacity(accent ? 0.58 : 0.25),
                                             Theme.border.opacity(0.2)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
    }
}

struct PremiumSectionHeading: View {
    let title: String
    var eyebrow: String = ""
    var count: String = ""

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                if !eyebrow.isEmpty {
                    Text(eyebrow.uppercased())
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.8)
                        .foregroundStyle(Theme.gold)
                }
                Text(title)
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(Theme.cream)
            }
            Spacer(minLength: 4)
            if !count.isEmpty {
                Text(count)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(Theme.champagne)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.gold.opacity(0.12), in: Capsule())
            }
        }
    }
}

struct PremiumPrimaryButtonStyle: ButtonStyle {
    var secondary: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(secondary ? Theme.champagne : Theme.ink)
            .frame(maxWidth: .infinity, minHeight: 49)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(secondary ? AnyShapeStyle(Theme.raised) : AnyShapeStyle(Theme.metal))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.champagne.opacity(secondary ? 0.25 : 0.7), lineWidth: 1)
            )
            .shadow(color: secondary ? .clear : Theme.gold.opacity(0.18), radius: 8, y: 3)
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct PremiumStat: View {
    let value: String
    let label: String
    let piece: PremiumChessPiece

    var body: some View {
        VStack(spacing: 6) {
            Text(piece.glyph)
                .font(.system(size: 26))
                .foregroundStyle(Theme.metal)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.cream)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.pale)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(Theme.raised.opacity(0.5), in: RoundedRectangle(cornerRadius: 13))
    }
}

struct PremiumChessBoardFrame<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.metal)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.champagne.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: Theme.gold.opacity(0.15), radius: 16, y: 7)
    }
}
