//
//  RetroTheme.swift
//  Antidote
//
//  Created by Codex on 2025-03-17.
//

import SwiftUI
import CoreText

enum DoseState {
    case idle
    case running
    case locked
}

enum BoosterState {
    case hidden
    case presented
    case granted
    case failed
}

struct RetroTheme {
    struct Palette {
        static let background = Color(hex: "#070417")
        static let panel = Color(hex: "#11092F")
        static let panelBorder = Color.white.opacity(0.12)
        static let primaryAccent = Color(hex: "#FF4FD8")
        static let secondaryAccent = Color(hex: "#34F5C5")
        static let highlight = Color(hex: "#7D5CFF")
        static let warning = Color(hex: "#FFDF6C")
        static let locked = Color(hex: "#FF4D6D")
        static let text = Color(hex: "#F7F5FF")
        static let mutedText = Color.white.opacity(0.55)
    }
    
    struct Typography {
        static func title(_ size: CGFloat) -> Font {
            Font.custom("PressStart2P-Regular", size: size)
        }
        
        static func body(_ size: CGFloat) -> Font {
            Font.custom("Orbitron-Bold", size: size)
        }
        
        static func mono(_ size: CGFloat) -> Font {
            Font.custom("PressStart2P-Regular", size: size)
        }
    }
    
    static func registerFonts() {
        let fontFiles = [
            "PressStart2P-Regular",
            "Orbitron-Bold"
        ]
        
        fontFiles.forEach { name in
            guard let url = fontURL(named: name) else {
                print("⚠️ Missing font resource: \(name).ttf")
                return
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
    
    private static func fontURL(named name: String) -> URL? {
        let candidates: [URL?] = [
            Bundle.main.url(forResource: name, withExtension: "ttf"),
            Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts"),
            Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Resources/Fonts")
        ]
        return candidates.compactMap { $0 }.first
    }
}

extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexString.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
