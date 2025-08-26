//
//  ExportSheetView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 8/16/25.
//

import UniformTypeIdentifiers
import SwiftUI

struct ExportSheetKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct ExportSheetType: FocusedValueKey {
    typealias Value = Binding<UTType>
}

extension FocusedValues {
    var showExportSheet: Binding<Bool>? {
        get { self[ExportSheetKey.self] }
        set { self[ExportSheetKey.self] = newValue }
    }
    var showExportType: Binding<UTType>? {
        get { self[ExportSheetType.self] }
        set { self[ExportSheetType.self] = newValue }
    }
}

struct ExportSheetButton: View {
    @FocusedValue(\.showExportSheet) private var showExportSheet
    @FocusedValue(\.showExportType) private var showExportType
    var viewType: UTType
    
    var body: some View {
        Button {
            showExportSheet?.wrappedValue = true
            showExportType?.wrappedValue = viewType
        } label: {
            Label("Save \(viewType.preferredFilenameExtension!.uppercased())", systemImage: "square.and.arrow.down.on.square")
        }
        .keyboardShortcut("E")
        .disabled(showExportSheet == nil)
    }
}

struct ExportSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showExportSheet: Bool
    var url: URL
    @Binding var viewType: UTType
    @Binding var graph: Graph
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Save File:")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.blue)
            Text(url.deletingPathExtension().appendingPathExtension(viewType.preferredFilenameExtension!).path)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            HStack {
                Spacer()
                Button("Cancel") {
                    showExportSheet = false
                    dismiss()
                }
                Button("Save") {
                    if let ext = viewType.preferredFilenameExtension {
                        let url = url.deletingPathExtension().appendingPathExtension(ext)
                        do {
                            print("save \(url.path)")
                            try graph.renderGraph(viewType: viewType).write(to: url)
                        } catch {
                            print("Save failed \(error)")
                        }
                    }
                    showExportSheet = false
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
    }
}
