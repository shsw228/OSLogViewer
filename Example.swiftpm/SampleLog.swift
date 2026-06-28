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

    // Several areas, each with a couple of topics, so the viewer's per-area topic
    // rows have real variety to show.
    static let uiLifecycle = Logger(subsystem: subsystem, category: "ui.lifecycle")
    static let uiGesture = Logger(subsystem: subsystem, category: "ui.gesture")
    static let networkRequest = Logger(subsystem: subsystem, category: "network.request")
    static let networkImage = Logger(subsystem: subsystem, category: "network.image")
    static let dataQuery = Logger(subsystem: subsystem, category: "data.query")
    static let dataCache = Logger(subsystem: subsystem, category: "data.cache")
    static let servicePayment = Logger(subsystem: subsystem, category: "service.payment")
    static let serviceAuth = Logger(subsystem: subsystem, category: "service.auth")

    /// Emit a spread of categories/levels so the viewer has content the moment it
    /// (or the sample) appears. Shows how the `<area>.<topic>` categories map onto
    /// the viewer's two-tier filter.
    static func emitShowcase() {
        uiLifecycle.notice("screen appeared name=Sample")
        uiGesture.debug("swipe direction=left")
        networkRequest.info("GET /v1/feed start")
        networkRequest.notice("GET /v1/feed status=200 items=24")
        networkImage.notice("loaded avatar bytes=10240")
        dataQuery.debug("fetch User rows=1")
        dataCache.notice("cache hit key=feed")
        serviceAuth.notice("token refreshed")
        servicePayment.notice("purchase begin product=pro.monthly")
        servicePayment.error("purchase failed reason=userCancelled")
    }
}
