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

extension FocusedValues {
    var showExportSheet: Binding<Bool>? {
        get { self[ExportSheetKey.self] }
        set { self[ExportSheetKey.self] = newValue }
    }
}

struct ExportSheetButton: View {
    @FocusedValue(\.showExportSheet) private var showExportSheet
    
    var body: some View {
        Button {
            showExportSheet?.wrappedValue = true
        } label: {
            Label("Export...", systemImage: "square.and.arrow.up")
        }
        .keyboardShortcut("E")
        .disabled(showExportSheet == nil)
    }
}

struct ExportSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showExportSheet: Bool
    @Binding var document: GraphvizDocument
    @Binding var format: UTType
    @Binding var graph: Graph

    var body: some View {
        NavigationSplitView {
            Text(document.name)
        }
        detail: {
            //            TextField("File Name", text: $document.name)
            Text(document.name)
            Picker("Format", selection: $format) {
                ForEach(GraphvizDocument.writableContentTypes, id: \.self) {
                    Text($0.preferredFilenameExtension!).tag($0.preferredFilenameExtension)
                }
            }
            .labelsHidden()
            HStack {
                Button("Save") {
//                    let data = try? graph.renderGraph(utType: format)
                    // write data
                    dismiss()
                }
                Button("Cancel") {
                    showExportSheet = false
                    dismiss()
                }
            }
        }
        .frame(minWidth: 300, minHeight: 200)
    }
}
