//
//  LogTextFile.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

import CoreTransferable
import UniformTypeIdentifiers

/// Transferable wrapper used by `ShareLink` so the system share sheet exports the
/// logs as a named plain-text file (Mail attaches it, Files saves it, etc.).
struct LogTextFile: Transferable {
    let text: String
    let fileName: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .plainText) { file in
            Data(file.text.utf8)
        }
        .suggestedFileName { $0.fileName }
    }
}
