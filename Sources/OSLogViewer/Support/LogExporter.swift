//
//  LogExporter.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum LogExporter {
    /// Write `text` to a temporary `.txt` file and return its URL. Used for the
    /// `onExport` callback path so the host app gets a ready-to-attach file.
    static func writeTemporaryFile(text: String, fileName: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try Data(text.utf8).write(to: url, options: .atomic)
        return url
    }
}
