//
//  LogCategory.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

/// Parsing for the `<area>.<topic>` category convention that drives the dynamic
/// two-tier filter. Pure and free of SwiftUI/OSLog so it is trivially testable.
enum LogCategory {
    /// `ui.framePicker` → `ui`. The whole category if there is no dot.
    static func area(of category: String) -> String {
        guard let dot = category.firstIndex(of: ".") else { return category }
        return String(category[..<dot])
    }

    /// `ui.framePicker` → `framePicker`. The whole category if there is no dot.
    static func topic(of category: String) -> String {
        guard let dot = category.firstIndex(of: ".") else { return category }
        return String(category[category.index(after: dot)...])
    }
}
