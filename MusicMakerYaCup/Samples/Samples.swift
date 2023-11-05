//
//  Samples.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 01.11.2023.
//

import Foundation

struct Samples {
    struct Drums {
        static let hit = Bundle.main.url(forResource: "Hit", withExtension: "wav")
        static let clap = Bundle.main.url(forResource: "Clap", withExtension: "wav")
        static let kick = Bundle.main.url(forResource: "Kick", withExtension: "wav")
        static let snare = Bundle.main.url(forResource: "Snare", withExtension: "wav")
    }

    struct Guitar {
        static let A = Bundle.main.url(forResource: "G_A", withExtension: "wav")
        static let B = Bundle.main.url(forResource: "G_B", withExtension: "wav")
        static let E = Bundle.main.url(forResource: "G_E", withExtension: "wav")
        static let G = Bundle.main.url(forResource: "G_G", withExtension: "wav")
    }

    struct Piano {
        static let A = Bundle.main.url(forResource: "P_A", withExtension: "wav")
        static let B = Bundle.main.url(forResource: "P_B", withExtension: "wav")
        static let C = Bundle.main.url(forResource: "P_C", withExtension: "wav")
        static let D = Bundle.main.url(forResource: "P_D", withExtension: "wav")
    }

    struct Trumpet {
        static let A = Bundle.main.url(forResource: "T_A", withExtension: "wav")
        static let C = Bundle.main.url(forResource: "T_C", withExtension: "wav")
        static let F = Bundle.main.url(forResource: "T_F", withExtension: "wav")
        static let G = Bundle.main.url(forResource: "T_G", withExtension: "wav")
    }
}
