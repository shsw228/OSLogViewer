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
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

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
        #if os(iOS)
        iOSBody
        #else
        macBody
        #endif
    }

    #if os(iOS)
    // ナビゲーションバー（Liquid Glass のスクロールエッジ）に載せる iOS レイアウト。
    private var iOSBody: some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
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
                ToolbarItem(placement: .topBarTrailing) { LogLevelMenu(model: model) }
                ToolbarItem(placement: .topBarTrailing) { copyControl }
                ToolbarItem(placement: .topBarTrailing) { reloadControl }
            }
            .sensoryFeedback(.success, trigger: copyCount)
            .task { await model.reload() }
    }
    #else
    // macOS はウィンドウ toolbar / searchable に頼らず、ビュー内のインラインバーに操作を置く
    // （Settings のタブや sheet などどこに埋め込んでも位置が崩れないため）。
    private var macBody: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TextField(osLogViewerString("Search by message, category, or time"), text: searchBinding)
                    .textFieldStyle(.roundedBorder)
                LogLevelMenu(model: model)
                copyControl
                reloadControl
            }
            // 右側の3コントロールの見た目・高さを揃える
            .buttonStyle(.bordered)
            .menuStyle(.button)
            .controlSize(.regular)
            .padding(8)
            Divider()
            if !model.entries.isEmpty {
                LogFilterBar(model: model)
                Divider()
            }
            content
        }
        .navigationTitle(title ?? osLogViewerString("Logs"))
        .task { await model.reload() }
    }
    #endif

    // Tap copies the filtered logs; the menu exposes export actions.
    private var copyControl: some View {
        Menu {
            exportMenuItems
        } label: {
            Image(systemName: "doc.on.doc")
        } primaryAction: {
            Self.copyToPasteboard(model.plainText(for: .filtered))
            copyCount += 1
        }
        .fixedSize()
        .disabled(model.entries.isEmpty)
        .accessibilityLabel(osLogViewerString("Copy logs"))
    }

    private var reloadControl: some View {
        Button {
            Task { await model.reload() }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(model.loadPhase.isLoading)
    }

    static func copyToPasteboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
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
                Label(
                    osLogViewerString("Export filtered logs"),
                    systemImage: "line.3.horizontal.decrease")
            }
            .disabled(model.filteredEntries.isEmpty)
            Button {
                runExport(.all, onExport)
            } label: {
                Label(osLogViewerString("Export all logs"), systemImage: "square.and.arrow.up")
            }
        } else {
            ShareLink(
                item: file(for: .filtered),
                preview: SharePreview(osLogViewerString("Filtered logs"))
            ) {
                Label(
                    osLogViewerString("Export filtered logs"),
                    systemImage: "line.3.horizontal.decrease")
            }
            .disabled(model.filteredEntries.isEmpty)
            ShareLink(item: file(for: .all), preview: SharePreview(osLogViewerString("All logs"))) {
                Label(osLogViewerString("Export all logs"), systemImage: "square.and.arrow.up")
            }
        }
    }

    private func file(for scope: LogExport.Scope) -> LogTextFile {
        LogTextFile(
            text: model.plainText(for: scope), fileName: model.suggestedFileName(for: scope))
    }

    private func runExport(_ scope: LogExport.Scope, _ handler: (LogExport) -> Void) {
        let text = model.plainText(for: scope)
        let fileName = model.suggestedFileName(for: scope)
        guard let url = try? LogExporter.writeTemporaryFile(text: text, fileName: fileName) else {
            return
        }
        handler(LogExport(scope: scope, text: text, fileURL: url))
    }

    @ViewBuilder
    private var content: some View {
        if case .failed(let message) = model.loadPhase {
            ContentUnavailableView {
                Label(
                    osLogViewerString("Could not load logs"),
                    systemImage: "exclamationmark.triangle")
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
                Label(
                    osLogViewerString("No matching logs"),
                    systemImage: "line.3.horizontal.decrease.circle")
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

