//
//  LogExport.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The result of an export action, handed to the host app's `onExport` handler so
/// it can route the logs (mail, save, etc.) however it likes.
public struct LogExport: Sendable {
    /// Which logs were exported.
    public enum Scope: Sendable {
        /// All loaded entries, ignoring the current filter/search.
        case all
        /// Only the entries matching the current filter/search.
        case filtered
    }

    public let scope: Scope
    /// The exported logs as plain text (oldest-first).
    public let text: String
    /// A temporary `.txt` file containing `text`, suitable for attaching/saving.
    public let fileURL: URL

    public init(scope: Scope, text: String, fileURL: URL) {
        self.scope = scope
        self.text = text
        self.fileURL = fileURL
    }
}
