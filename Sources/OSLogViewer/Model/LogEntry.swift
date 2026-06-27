//
//  LogEntry.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import OSLog

/// One decoded log line. Sendable so it can cross the actor boundary from the
/// background fetch back to the main-actor model.
struct LogEntry: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let level: OSLogEntryLog.Level
    let category: String
    let message: String
}

/// Progress of a reload. Kept separate from `entries` (which is appended to
/// incrementally) so loading does not churn the entry list.
enum LoadPhase {
    case idle
    case loading
    case failed(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
