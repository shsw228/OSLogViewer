//
//  OSLogExport.swift
//  OSLogViewer
//
//  Copyright 2026 Kengo Tate
//  SPDX-License-Identifier: Apache-2.0
//
//  Headless (UI-independent) access to the same logs the viewer shows. Use this to
//  build flows like a Settings "Report a problem" action that attaches recent logs
//  to a mail/share sheet without presenting the viewer.
//

import Foundation

public enum OSLogExport {
    /// Recent logs for `subsystem` (the last `lookback` seconds), narrowed by
    /// `filter`, as plain text, oldest-first — the same format the viewer exports.
    /// The default empty filter exports everything.
    public static func text(
        subsystem: String,
        lookback: TimeInterval = 600,
        filter: LogFilter = .init()
    ) async throws -> String {
        try Task.checkCancellation()
        let from = Date().addingTimeInterval(-lookback)
        let fetchTask = Task.detached(priority: .utility) {
            try OSLogStoreReader.fetch(subsystem: subsystem, since: from)
        }
        // Propagate cancellation to the detached fetch. `OSLogStore.getEntries` is
        // synchronous and cannot be interrupted mid-call, so this mainly ensures we
        // skip the downstream filtering/formatting/file-write once cancelled.
        let entries = try await withTaskCancellationHandler {
            try await fetchTask.value
        } onCancel: {
            fetchTask.cancel()
        }
        try Task.checkCancellation()
        return LogTextFormatter.plainText(filter.apply(to: entries))
    }

    /// Filtered recent logs written to a temporary `.txt` file, ready to attach to a
    /// mail composer or share sheet. Returns the file URL.
    public static func temporaryFile(
        subsystem: String,
        lookback: TimeInterval = 600,
        filter: LogFilter = .init(),
        fileName: String? = nil
    ) async throws -> URL {
        let text = try await text(subsystem: subsystem, lookback: lookback, filter: filter)
        try Task.checkCancellation()
        let name = fileName ?? "\(subsystem)-\(LogFormat.fileTimestamp.string(from: Date())).txt"
        return try LogExporter.writeTemporaryFile(text: text, fileName: name)
    }
}
