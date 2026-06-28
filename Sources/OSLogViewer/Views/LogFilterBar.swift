//
//  LogFilterBar.swift
//  OSLogViewer
//
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// The dynamic two-tier filter: area chips (built from the logged categories) and,
/// when an area is selected, the topic chips under it.
struct LogFilterBar: View {
    let model: LogViewerModel

    var body: some View {
        // Horizontal padding lives on the scroll *content* (not the container) so the
        // scrollers run edge-to-edge and chips clip at the true screen edge instead of
        // being cut off at a dead inset margin.
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Chip(
                            label: osLogViewerString("All"),
                            isSelected: model.selectedAreas.isEmpty, tint: .gray
                        ) {
                            withAnimation(.snappy) { model.selectAllAreas() }
                        }
                        ForEach(model.availableAreas, id: \.self) { area in
                            Chip(
                                label: area, isSelected: model.selectedAreas.contains(area),
                                tint: AreaColor.color(for: area)
                            ) {
                                withAnimation(.snappy) { model.toggleArea(area) }
                            }
                        }
                    }
                    .padding(.leading, 16)
                }
                entryCount
                    .padding(.trailing, 16)
            }

            // One horizontal topic row per selected area; rows stack downward as more
            // areas are selected. Each row is tinted with its area's color.
            if !model.selectedAreas.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(model.selectedAreasSorted, id: \.self) { area in
                        topicRow(for: area)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, 8)
        .animation(.snappy, value: model.selectedAreas)
        .animation(.snappy, value: model.availableAreas)
    }

    /// One area's topics as a horizontal-scrolling row, tinted with the area's color.
    private func topicRow(for area: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.topicCategories(inArea: area), id: \.self) { category in
                    Chip(
                        label: LogCategory.topic(of: category),
                        isSelected: model.selectedCategories.contains(category),
                        compact: true,
                        tint: AreaColor.color(for: area)
                    ) {
                        withAnimation(.snappy) { model.toggleCategory(category) }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var entryCount: some View {
        Text(osLogViewerString("\(model.filteredEntries.count) entries"))
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .fixedSize()
            // Roll the count digit-by-digit as the filter changes the match total.
            .contentTransition(.numericText())
            .animation(.snappy, value: model.filteredEntries.count)
    }
}
