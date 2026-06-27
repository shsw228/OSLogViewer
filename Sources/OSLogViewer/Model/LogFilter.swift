//
//  LogFilter.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//
//  The selection criteria shared by the viewer and the headless export. Pass one to
//  `OSLogExport` to export only the logs you want (e.g. errors, or one area).
//

import Foundation
import OSLog

public struct LogFilter: Sendable {
    /// Only these levels. Empty = all levels.
    public var levels: Set<OSLogEntryLog.Level>
    /// Only these areas — the `<area>` prefix of a `<area>.<topic>` category. Empty = all.
    public var areas: Set<String>
    /// Only these full categories (`<area>.<topic>`). Empty = all.
    public var categories: Set<String>
    /// Case-insensitive substring matched against message / category / level / time.
    /// `nil` or empty = no text filter.
    public var searchText: String?

    public init(
        levels: Set<OSLogEntryLog.Level> = [],
        areas: Set<String> = [],
        categories: Set<String> = [],
        searchText: String? = nil
    ) {
        self.levels = levels
        self.areas = areas
        self.categories = categories
        self.searchText = searchText
    }

    /// Whether every criterion is empty (i.e. matches everything).
    var isEmpty: Bool {
        levels.isEmpty && areas.isEmpty && categories.isEmpty
            && (searchText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    func apply(to entries: [LogEntry]) -> [LogEntry] {
        let query = searchText?.trimmingCharacters(in: .whitespacesAndNewlines)
        return entries.filter { entry in
            if !levels.isEmpty, !levels.contains(entry.level) { return false }
            if !areas.isEmpty, !areas.contains(LogCategory.area(of: entry.category)) { return false }
            if !categories.isEmpty, !categories.contains(entry.category) { return false }
            if let query, !query.isEmpty, !Self.matches(entry, query: query) { return false }
            return true
        }
    }

    static func matches(_ entry: LogEntry, query: String) -> Bool {
        if entry.message.localizedStandardContains(query) { return true }
        if entry.category.localizedStandardContains(query) { return true }
        if entry.level.displayLabel.localizedStandardContains(query) { return true }
        return LogFormat.timestamp.string(from: entry.date).localizedStandardContains(query)
    }
}
