//
//  LogTextFormatter.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

/// Plain-text rendering of log entries, shared by the in-viewer copy/export and
/// the headless ``OSLogExport`` API so the output format stays identical.
enum LogTextFormatter {
    static func plainText(_ entries: [LogEntry]) -> String {
        entries
            .map { entry in
                "\(LogFormat.timestamp.string(from: entry.date)) [\(entry.level.displayLabel)] \(entry.category): \(entry.message)"
            }
            .joined(separator: "\n")
    }
}
