# ``OSLogViewer``

A self-contained SwiftUI viewer for the current process's `OSLogStore`, with a
dynamic `<area>.<topic>` category filter, level filter, search, copy/export, and a
headless export API.

## Overview

Embed ``OSLogViewer/OSLogViewer`` inside a navigation container and pass your
`os.Logger` subsystem:

```swift
import OSLogViewer
import SwiftUI

NavigationStack {
    OSLogViewer(subsystem: "com.example.app")
}
```

The filter is generated from the logs themselves — there is no fixed category
enum. Categories written as `<area>.<topic>` (e.g. `ui.capture`, `service.camera`)
become a two-tier **area → topic** filter that grows as logs arrive.

### Reporting a problem

To collect recent logs without presenting the viewer — for a "report a problem"
flow that attaches them to mail or a share sheet — use ``OSLogExport``, optionally
narrowed by a ``LogFilter``:

```swift
let url = try await OSLogExport.temporaryFile(
    subsystem: "com.example.app",
    lookback: 1800,
    filter: LogFilter(levels: [.error, .fault])
)
```

### Log levels

`OSLogStore` keeps `.debug` / `.info` entries only in an in-memory ring buffer
that the system may reclaim (e.g. around backgrounding). Use `.notice` or higher
for events that must survive such transitions.

## Topics

### Viewer

- ``OSLogViewer/OSLogViewer``

### Headless export

- ``OSLogExport``
- ``LogFilter``
- ``LogExport``
