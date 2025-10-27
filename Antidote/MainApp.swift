//
//  MainApp.swift
//  Antidote
//
//  Created by Mark T on 2025-09-02.
//

import SwiftUI

@main
struct MainApp: App {
    init() {
        RetroTheme.registerFonts()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
