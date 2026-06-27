//
//  OSLogViewer.swift
//  OSLogViewer
//
//  Copyright 2026 Kengo Tate
//  SPDX-License-Identifier: Apache-2.0
//
//  A self-contained SwiftUI viewer for the current process's `OSLogStore`.
//
//  The filter is generated from the log data itself — there is no fixed category
//  enum. `<area>.<topic>` categories are split into a dynamic two-tier filter.
//  Only the subsystem is injected; UI strings ship in this package's String
//  Catalog (`Bundle.module`), with the navigation `title` overridable.
//
//  Usage (embed inside a navigation container):
//
//      NavigationStack { OSLogViewer(subsystem: "com.example.app") }
//
//  Note: `OSLogStore` keeps `.debug` / `.info` entries only in an in-memory ring
//  buffer that the system may reclaim (e.g. around backgrounding). Use `.notice`
//  or higher for events that must survive such transitions.
//

import OSLog
import SwiftUI
import UIKit

@MainActor
public struct OSLogViewer: View {
    @State private var model: LogViewerModel
    private let title: String?
    private let onExport: ((LogExport) -> Void)?
    @State private var copyCount = 0

    /// - Parameters:
    ///   - subsystem: The `os.Logger` subsystem to read (`OSLogStore` predicate filter).
    ///   - title: Navigation title. When `nil`, a localized "Logs" is used.
    ///   - onExport: Optional handler for the export actions (long-press the copy
    ///     button). When provided, the host app receives a ``LogExport`` (text + a
    ///     temporary file) to route to mail/save itself. When `nil`, the viewer
    ///     presents the system share sheet via `ShareLink`.
    public init(
        subsystem: String,
        title: String? = nil,
        onExport: ((LogExport) -> Void)? = nil
    ) {
        _model = State(initialValue: LogViewerModel(subsystem: subsystem))
        self.title = title
        self.onExport = onExport
    }

    public var body: some View {
        // Keep the scrollable content as the root so it slides under the navigation
        // bar — that's what lets the bar adopt the Liquid Glass scroll-edge effect on
        // iOS 26+. The filter bar floats as a top safe-area inset instead of being
        // stacked above the list (which would pin a flat bar under the nav bar).
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                // The filter is generated from real data, so it is hidden when there
                // are no logs. When search / level filtering yields zero rows,
                // `entries` is still non-empty so the filter stays (and is recoverable).
                if !model.entries.isEmpty {
                    VStack(spacing: 0) {
                        LogFilterBar(model: model)
                        Divider()
                    }
                    .background(.bar)
                }
            }
            .navigationTitle(title ?? osLogViewerString("Logs"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: searchBinding,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text(osLogViewerString("Search by message, category, or time"))
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                LogLevelMenu(model: model)
            }
            ToolbarItem(placement: .topBarTrailing) {
                // Tap copies the filtered logs; long-press reveals the export menu.
                Menu {
                    exportMenuItems
                } label: {
                    Image(systemName: "doc.on.doc")
                } primaryAction: {
                    UIPasteboard.general.string = model.plainText(for: .filtered)
                    copyCount += 1
                }
                .disabled(model.entries.isEmpty)
                .accessibilityLabel(osLogViewerString("Copy logs"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await model.reload() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(model.loadPhase.isLoading)
            }
        }
        .sensoryFeedback(.success, trigger: copyCount)
        .task { await model.reload() }
    }

    private var searchBinding: Binding<String> {
        Binding(get: { model.searchText }, set: { model.searchText = $0 })
    }

    /// Export entries in the long-press menu. With an `onExport` handler the host
    /// app receives the export; otherwise a `ShareLink` presents the system share
    /// sheet (mail / save to Files / …).
    @ViewBuilder
    private var exportMenuItems: some View {
        if let onExport {
            Button {
                runExport(.filtered, onExport)
            } label: {
                Label(osLogViewerString("Export filtered logs"), systemImage: "line.3.horizontal.decrease")
            }
            .disabled(model.filteredEntries.isEmpty)
            Button {
                runExport(.all, onExport)
            } label: {
                Label(osLogViewerString("Export all logs"), systemImage: "square.and.arrow.up")
            }
        } else {
            ShareLink(item: file(for: .filtered), preview: SharePreview(osLogViewerString("Filtered logs"))) {
                Label(osLogViewerString("Export filtered logs"), systemImage: "line.3.horizontal.decrease")
            }
            .disabled(model.filteredEntries.isEmpty)
            ShareLink(item: file(for: .all), preview: SharePreview(osLogViewerString("All logs"))) {
                Label(osLogViewerString("Export all logs"), systemImage: "square.and.arrow.up")
            }
        }
    }

    private func file(for scope: LogExport.Scope) -> LogTextFile {
        LogTextFile(text: model.plainText(for: scope), fileName: model.suggestedFileName(for: scope))
    }

    private func runExport(_ scope: LogExport.Scope, _ handler: (LogExport) -> Void) {
        let text = model.plainText(for: scope)
        let fileName = model.suggestedFileName(for: scope)
        guard let url = try? LogExporter.writeTemporaryFile(text: text, fileName: fileName) else { return }
        handler(LogExport(scope: scope, text: text, fileURL: url))
    }

    @ViewBuilder
    private var content: some View {
        if case .failed(let message) = model.loadPhase {
            ContentUnavailableView {
                Label(osLogViewerString("Could not load logs"), systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            }
        } else if model.loadPhase.isLoading && model.entries.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.entries.isEmpty {
            ContentUnavailableView {
                Label(osLogViewerString("No log entries"), systemImage: "doc.text.magnifyingglass")
            } description: {
                Text(osLogViewerString("Perform an action in the app, then reload."))
            }
        } else if model.displayEntries.isEmpty {
            // Logs exist but search / level filtering matched nothing. The recovery
            // controls (search bar, level menu) live outside this body.
            ContentUnavailableView {
                Label(osLogViewerString("No matching logs"), systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text(osLogViewerString("No logs match the current filter or search."))
            }
        } else {
            list
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(model.displayEntries) { entry in
                    LogRow(entry: entry)
                    Divider()
                }
            }
        }
        // Scope refreshable to the log list only; on the whole body it propagates via
        // environment to the filter's horizontal scrollers and misfires there.
        .refreshable { await model.reload() }
    }
}
