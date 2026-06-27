//
//  Chip.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// A capsule filter chip. `tint` groups chips by tier (area vs topic) so it is
/// clear which tier a chip belongs to even when unselected.
struct Chip: View {
    let label: String
    let isSelected: Bool
    var compact: Bool = false
    var tint: Color = .accentColor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font((compact ? Font.caption2 : Font.caption).weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : tint)
                .padding(.horizontal, compact ? 10 : 12)
                .padding(.vertical, compact ? 5 : 8)
                .modifier(ChipBackground(isSelected: isSelected, tint: tint))
        }
        .buttonStyle(.plain)
    }
}

/// Chip background: Liquid Glass on iOS 26+, a tinted capsule on older systems.
/// The legacy branch is isolated in the `else` so it (and the `#available`) can be
/// deleted wholesale once the deployment target reaches iOS 26.
private struct ChipBackground: ViewModifier {
    let isSelected: Bool
    let tint: Color

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(
                isSelected ? .regular.tint(tint).interactive() : .regular.interactive(),
                in: Capsule()
            )
        } else {
            // LEGACY (pre-iOS 26): tinted capsule.
            content.background(
                isSelected ? tint : tint.opacity(0.15),
                in: Capsule()
            )
        }
    }
}
