//
//  MusicalInstrument.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 26.11.2023.
//

import UIKit

enum MusicalInstrument: CaseIterable {
    case drums, guitar, piano, trumpet

    var icon: UIImage? {
        switch self {
        case .drums:
            return .drumsIcon
        case .guitar:
            return .guitarIcon
        case .piano:
            return .keysIcon
        case .trumpet:
            return .trumpetIcon
        }
    }

    var name: String {
        switch self {
        case .drums:
            return "Барабаны"
        case .guitar:
            return "Гитара"
        case .piano:
            return "Пианино"
        case .trumpet:
            return "Труба"
        }
    }

    var samples: [Sample] {
        switch self {
        case .drums:
            return [
                Sample(name: "Бас", url: Samples.Drums.kick, instrument: self),
                Sample(name: "Удар", url: Samples.Drums.hit, instrument: self),
                Sample(name: "Хлопок", url: Samples.Drums.clap, instrument: self),
                Sample(name: "Снэр", url: Samples.Drums.snare, instrument: self)
            ]
        case .guitar:
            return [
                Sample(name: "#E", url: Samples.Guitar.E, instrument: self),
                Sample(name: "#A", url: Samples.Guitar.A, instrument: self),
                Sample(name: "#B", url: Samples.Guitar.G, instrument: self),
                Sample(name: "#G", url: Samples.Guitar.B, instrument: self)
            ]
        case .piano:
            return [
                Sample(name: "C", url: Samples.Piano.C, instrument: self),
                Sample(name: "A", url: Samples.Piano.A, instrument: self),
                Sample(name: "B", url: Samples.Piano.B, instrument: self),
                Sample(name: "D", url: Samples.Piano.D, instrument: self)
            ]
        case .trumpet:
            return [
                Sample(name: "Db/C#", url: Samples.Trumpet.C, instrument: self),
                Sample(name: "F", url: Samples.Trumpet.F, instrument: self),
                Sample(name: "G", url: Samples.Trumpet.G, instrument: self),
                Sample(name: "Ab/G#", url: Samples.Trumpet.A, instrument: self)
            ]
        }
    }
}
