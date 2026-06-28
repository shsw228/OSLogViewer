//
//  AreaColor.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// A stable color per `<area>` so an area chip and all of its topic chips share a
/// hue — making it clear which area a topic belongs to. Deterministic across
/// launches (does not use `String.hashValue`, which is randomized per process).
enum AreaColor {
    private static let palette: [Color] = [
        .blue, .green, .orange, .purple, .pink, .teal, .indigo, .mint, .red, .cyan,
    ]

    static func color(for area: String) -> Color {
        var hash: UInt64 = 5381
        for byte in area.utf8 {
            hash = hash &* 33 &+ UInt64(byte)
        }
        return palette[Int(hash % UInt64(palette.count))]
    }
}
