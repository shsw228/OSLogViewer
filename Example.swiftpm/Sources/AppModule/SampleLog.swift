//
//  SampleLog.swift
//  OSLogViewerSample
//
//  SPDX-License-Identifier: Apache-2.0
//
//  How to write logs so OSLogViewer can present them.
//
//  1. Pick ONE subsystem for your app and pass it to `OSLogViewer(subsystem:)`.
//  2. Make an `os.Logger` per concern, with a category in `<area>.<topic>` form.
//     OSLogViewer turns the `<area>` prefix into the top-level filter and the
//     `<topic>` into the second tier — so a consistent convention pays off.
//  3. Levels: `.debug`/`.info` live only in an in-memory ring buffer and can be
//     dropped (e.g. around backgrounding). Use `.notice` or higher for events you
//     want to survive. Keep values non-PII; mark anything dynamic `.public` if you
//     need it readable without a debugger attached.
//

import OSLog

enum SampleLog {
    /// One subsystem for the whole sample app; the same value is handed to the viewer.
    static let subsystem = "com.example.OSLogViewerSample"

    static let ui = Logger(subsystem: subsystem, category: "ui.sample")
    static let network = Logger(subsystem: subsystem, category: "network.request")
    static let database = Logger(subsystem: subsystem, category: "data.store")
    static let payment = Logger(subsystem: subsystem, category: "service.payment")

    /// Emit a spread of categories/levels so the viewer has content the moment it
    /// (or the sample) appears. Shows how the `<area>.<topic>` categories map onto
    /// the viewer's two-tier filter.
    static func emitShowcase() {
        ui.notice("screen appeared name=Sample")
        network.info("GET /v1/feed start")
        network.notice("GET /v1/feed status=200 items=24")
        database.debug("fetch User rows=1")
        payment.notice("purchase begin product=pro.monthly")
        payment.error("purchase failed reason=userCancelled")
    }
}
