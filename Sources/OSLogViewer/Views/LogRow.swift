//
//  LogRow.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// A single log line: a colored level badge, category, timestamp, and the message.
struct LogRow: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(entry.level.displayLabel)
                    .font(.caption2.weight(.bold).monospaced())
                    .foregroundStyle(entry.level.tint)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(entry.level.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 3))
                Text(entry.category)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(LogFormat.timestamp.string(from: entry.date))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            Text(entry.message)
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
    }
}
