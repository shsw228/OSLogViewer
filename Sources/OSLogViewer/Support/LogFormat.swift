//
//  LogFormat.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum LogFormat {
    /// Shared timestamp formatter used by both the rows and the copy export so
    /// they stay identical.
    static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    /// Filename-safe, locale-independent timestamp for exported log files.
    static let fileTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}
