//
//  ContentView.swift
//  Example
//
//  SPDX-License-Identifier: Apache-2.0
//
//  A small showcase of OSLogViewer, in the spirit of a debug-menu example:
//   - emit logs across categories/levels (see how logging looks),
//   - open the log viewer (display),
//   - request recent logs as a file (export / "log request").
//
//  Strings are plain SwiftUI literals; the bundled Localizable.xcstrings localizes
//  them against the app's main bundle (en/ja). The viewer's own UI is localized
//  separately inside the OSLogViewer package.
//

import OSLog
import OSLogViewer
import SwiftUI

struct ContentView: View {
    private enum ExportKind { case all, errors }

    /// Holds the exported file so a ShareLink can offer it after "Request logs".
    @State private var requestedLogFile: URL?
    /// Which export is in flight (nil = none). Only that button shows a spinner.
    @State private var exporting: ExportKind?
    @State private var isViewerPresented = false

    var body: some View {
        NavigationStack {
            List {
                emitSection
                viewerSection
                exportSection
            }
            .navigationTitle("OSLogViewer Sample")
        }
        // Seed some events when the sample appears so there is something to show.
        .task { SampleLog.emitShowcase() }
        .sheet(isPresented: $isViewerPresented) {
            NavigationStack {
                OSLogViewer(subsystem: SampleLog.subsystem)
                    // Also emit on viewer open, to show logs arriving live.
                    .onAppear { SampleLog.emitShowcase() }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { isViewerPresented = false }
                        }
                    }
            }
        }
    }

    /// Each button writes one log. Tap a few, then open the viewer to see them.
    private var emitSection: some View {
        Section {
            Button("Network request (.notice)") {
                SampleLog.network.notice("GET /v1/items status=200 items=12")
            }
            Button("Database read (.debug)") {
                SampleLog.database.debug("fetch rows=42")
            }
            Button("UI event (.notice)") {
                SampleLog.ui.notice("tapped sample button")
            }
            Button("Payment error (.error)") {
                SampleLog.payment.error("charge failed code=insufficient_funds")
            }
        } header: {
            Text("Emit logs")
        } footer: {
            Text("`Logger(subsystem:category:)` with a `<area>.<topic>` category. The area becomes the top-level filter in the viewer.")
        }
    }

    private var viewerSection: some View {
        Section {
            Button("Open log viewer") {
                isViewerPresented = true
            }
        } header: {
            Text("Display")
        } footer: {
            Text("`OSLogViewer(subsystem:)` reads this process's logs for the given subsystem.")
        }
    }

    private var exportSection: some View {
        Section {
            Button {
                requestLogs(.all)
            } label: {
                exportLabel("Request recent logs", kind: .all)
            }
            .disabled(exporting != nil)

            Button {
                requestLogs(.errors)
            } label: {
                exportLabel("Request errors only", kind: .errors)
            }
            .disabled(exporting != nil)

            if let requestedLogFile {
                ShareLink(item: requestedLogFile) {
                    Label("Share log file", systemImage: "square.and.arrow.up")
                }
            }
        } header: {
            Text("Export (log request)")
        } footer: {
            Text("`OSLogExport.temporaryFile(subsystem:lookback:filter:)` collects recent logs into a .txt — pass a `LogFilter` to export only what you need (e.g. errors, or one area).")
        }
    }

    @ViewBuilder
    private func exportLabel(_ title: LocalizedStringKey, kind: ExportKind) -> some View {
        // Only the tapped button spins; the other just disables with its label.
        if exporting == kind {
            ProgressView()
        } else {
            Text(title)
        }
    }

    private func requestLogs(_ kind: ExportKind) {
        exporting = kind
        Task {
            defer { exporting = nil }
            let filter: LogFilter = kind == .errors ? LogFilter(levels: [.error, .fault]) : .init()
            requestedLogFile = try? await OSLogExport.temporaryFile(
                subsystem: SampleLog.subsystem,
                lookback: 600,
                filter: filter
            )
        }
    }
}

#Preview {
    ContentView()
}
