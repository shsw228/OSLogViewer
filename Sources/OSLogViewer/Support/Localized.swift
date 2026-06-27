//
//  Localized.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Resolve a UI string from this package's String Catalog (`Bundle.module`).
/// SwiftUI's `Text("literal")` resolves against the *main* bundle, so package
/// strings must go through this to pick up the bundled localizations.
func osLogViewerString(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: .module)
}
