//
//  LogLevel+Presentation.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

import OSLog
import SwiftUI

extension OSLogEntryLog.Level {
    /// Levels offered in the level filter menu. `.undefined` is not listed and is
    /// always shown.
    static var selectable: [OSLogEntryLog.Level] {
        [.debug, .info, .notice, .error, .fault]
    }

    var displayLabel: String {
        switch self {
        case .debug: "DEBUG"
        case .info: "INFO"
        case .notice: "NOTICE"
        case .error: "ERROR"
        case .fault: "FAULT"
        case .undefined: "—"
        @unknown default: "—"
        }
    }

    var tint: Color {
        switch self {
        case .debug: .secondary
        case .info: .blue
        case .notice: .indigo
        case .error: .orange
        case .fault: .red
        case .undefined: .gray
        @unknown default: .gray
        }
    }

    var menuSymbol: String {
        switch self {
        case .debug: "ladybug"
        case .info: "info.circle"
        case .notice: "bell"
        case .error: "exclamationmark.triangle"
        case .fault: "exclamationmark.octagon"
        case .undefined: "questionmark.circle"
        @unknown default: "questionmark.circle"
        }
    }
}
