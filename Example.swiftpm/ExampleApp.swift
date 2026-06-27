//
//  ExampleApp.swift
//  Example
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Thin runnable wrapper around `SampleView`.
//  Run this Example.swiftpm in Xcode to try logging → viewing → exporting.
//

import SwiftUI

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            SampleView()
        }
    }
}
