//
//  LogLevelMenu.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

import OSLog
import SwiftUI

/// Toolbar level filter. Leading "All items" is selected while no level is
/// restricted; clearing every level falls back to it, so there is no explicit
/// "deselect all".
struct LogLevelMenu: View {
    let model: LogViewerModel

    var body: some View {
        Menu {
            Toggle(
                isOn: Binding(
                    get: { model.isShowingAllLevels },
                    set: { isOn in if isOn { model.showAllLevels() } }
                )
            ) {
                Label(osLogViewerString("All items"), systemImage: "square.stack.3d.up")
            }
            Divider()
            ForEach(OSLogEntryLog.Level.selectable, id: \.self) { level in
                Toggle(
                    isOn: Binding(
                        get: { model.enabledLevels.contains(level) },
                        set: { model.setLevel(level, enabled: $0) }
                    )
                ) {
                    Label(level.displayLabel, systemImage: level.menuSymbol)
                }
            }
        } label: {
            Image(
                systemName: model.isShowingAllLevels
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill")
        }
        // Keep the menu open on tap so multiple levels can be toggled in a row（iOS のみ）。
        #if os(iOS)
        .menuActionDismissBehavior(.disabled)
        #endif
        .accessibilityLabel(osLogViewerString("Filter by level"))
    }
}
