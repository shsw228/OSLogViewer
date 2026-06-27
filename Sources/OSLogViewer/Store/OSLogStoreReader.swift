//
//  OSLogStoreReader.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import OSLog

/// Reads the current process's `OSLogStore`. Nonisolated so it can run off the
/// main actor inside a detached task.
enum OSLogStoreReader {
    static func fetch(subsystem: String, since date: Date) throws -> [LogEntry] {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let position = store.position(date: date)
        let predicate = NSPredicate(format: "subsystem == %@", subsystem)
        let raw = try store.getEntries(at: position, matching: predicate)
        return raw.compactMap { entry in
            guard let logEntry = entry as? OSLogEntryLog else { return nil }
            return LogEntry(
                date: logEntry.date,
                level: logEntry.level,
                category: logEntry.category,
                message: logEntry.composedMessage
            )
        }
    }
}
