//
//  LogViewerModel.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Owns all viewer state and logic: the loaded entries, the filter selection, and
//  the derived/filtered output. Kept free of SwiftUI views so the filtering core
//  is testable on its own.
//

import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class LogViewerModel {
    let subsystem: String

    private(set) var entries: [LogEntry] = []
    private(set) var loadPhase: LoadPhase = .idle

    /// Selected areas (prefix before the first `.`). Empty = all areas.
    var selectedAreas: Set<String> = []
    /// Full categories selected to narrow within the chosen areas. Empty = all topics.
    var selectedCategories: Set<String> = []
    /// Visible log levels. **Empty = all levels (All items)**.
    var enabledLevels: Set<OSLogEntryLog.Level> = []
    var searchText = ""

    /// Where the next `reload()` starts from. `nil` means the initial load.
    private var nextFetchFrom: Date?
    /// Time window scanned on the first load (`OSLogStore.getEntries` decodes and
    /// predicate-evaluates every entry, so scanning the whole lifetime is costly).
    private static let initialLookback: TimeInterval = 60 * 10

    init(subsystem: String) {
        self.subsystem = subsystem
    }

    // MARK: - Derived output

    /// The current selection expressed as a `LogFilter` — the same type the headless
    /// export takes, so viewer and export share one filtering implementation.
    var activeFilter: LogFilter {
        LogFilter(
            levels: enabledLevels,
            areas: selectedAreas,
            categories: selectedCategories,
            searchText: searchText
        )
    }

    var filteredEntries: [LogEntry] {
        activeFilter.apply(to: entries)
    }

    /// Newest first.
    var displayEntries: [LogEntry] {
        Array(filteredEntries.reversed())
    }

    /// Areas present in the loaded logs (sorted). Grows as logs arrive.
    var availableAreas: [String] {
        Set(entries.map { LogCategory.area(of: $0.category) }).sorted()
    }

    /// Selected areas in stable display order. One topic row is shown per entry.
    var selectedAreasSorted: [String] {
        selectedAreas.sorted()
    }

    /// Full categories (`<area>.<topic>`) that belong to `area`, sorted. Each selected
    /// area renders its own horizontal topic row.
    func topicCategories(inArea area: String) -> [String] {
        let cats = entries.map(\.category).filter { LogCategory.area(of: $0) == area }
        return Set(cats).sorted()
    }

    /// Logs for the given scope as plain text, oldest-first. `.filtered` honors the
    /// current filter/search; `.all` exports every loaded entry.
    func plainText(for scope: LogExport.Scope) -> String {
        LogTextFormatter.plainText(scope == .all ? entries : filteredEntries)
    }

    /// Suggested filename for an exported log file, e.g.
    /// `com.example.app-filtered-20260627-203000.txt`.
    func suggestedFileName(for scope: LogExport.Scope) -> String {
        let scopeName = scope == .all ? "all" : "filtered"
        let stamp = LogFormat.fileTimestamp.string(from: Date())
        return "\(subsystem)-\(scopeName)-\(stamp).txt"
    }

    // MARK: - Selection

    func toggleArea(_ area: String) {
        if selectedAreas.contains(area) {
            selectedAreas.remove(area)
        } else {
            selectedAreas.insert(area)
        }
        // Drop topic selections outside the chosen areas; clearing all areas clears topics.
        if selectedAreas.isEmpty {
            selectedCategories.removeAll()
        } else {
            selectedCategories = selectedCategories.filter { selectedAreas.contains(LogCategory.area(of: $0)) }
        }
    }

    func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    func selectAllAreas() {
        selectedAreas.removeAll()
        selectedCategories.removeAll()
    }

    var isShowingAllLevels: Bool {
        enabledLevels.isEmpty
    }

    func showAllLevels() {
        enabledLevels = []
    }

    func setLevel(_ level: OSLogEntryLog.Level, enabled: Bool) {
        if enabled { enabledLevels.insert(level) } else { enabledLevels.remove(level) }
    }

    // MARK: - Loading

    /// Re-read logs. The first load scans the last `initialLookback` seconds;
    /// later loads fetch only entries after the previous latest and append.
    func reload() async {
        loadPhase = .loading
        let from = nextFetchFrom ?? Date().addingTimeInterval(-Self.initialLookback)
        let isInitial = nextFetchFrom == nil
        let subsystem = self.subsystem
        do {
            let loaded = try await Task.detached(priority: .userInitiated) {
                try OSLogStoreReader.fetch(subsystem: subsystem, since: from)
            }.value
            if isInitial {
                entries = loaded
            } else {
                entries.append(contentsOf: loaded)
            }
            // Advance 1ms past the latest entry so it is not picked up twice. With zero
            // entries reuse `from` (the store position returns entries at/after the time).
            nextFetchFrom = (loaded.last?.date ?? from).addingTimeInterval(0.001)
            pruneSelectionsToAvailableData()
            loadPhase = .idle
        } catch {
            loadPhase = .failed(String(describing: error))
        }
    }

    /// Drop area / category selections that no longer exist in the data. `entries`
    /// is append-only today (so usually a no-op), but this guards against a stale
    /// selection pinning the view to zero rows if fetching ever changes.
    private func pruneSelectionsToAvailableData() {
        let presentAreas = Set(entries.map { LogCategory.area(of: $0.category) })
        selectedAreas.formIntersection(presentAreas)
        let presentCategories = Set(entries.map(\.category))
        selectedCategories.formIntersection(presentCategories)
    }
}
