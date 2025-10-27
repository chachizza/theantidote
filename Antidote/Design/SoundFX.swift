//
//  SoundFX.swift
//  Antidote
//
//  Created by Codex on 2025-03-17.
//

import Foundation
import AudioToolbox

final class RetroSoundPlayer {
    func playLockClick() {
        AudioServicesPlaySystemSound(1105) // Retro style click
    }
    
    func playToggle() {
        AudioServicesPlaySystemSound(1100)
    }
    
    func playButton() {
        AudioServicesPlaySystemSound(1104)
    }
}
