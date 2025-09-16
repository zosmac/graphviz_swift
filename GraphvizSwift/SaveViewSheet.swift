//
//  SaveViewSheet.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 8/16/25.
//

import UniformTypeIdentifiers
import SwiftUI

extension FocusedValues {
    @Entry var saveViewPresented: Binding<Bool>?
    @Entry var saveViewType: Binding<UTType>?
}

struct SaveViewButton: View {
    @FocusedValue(\.saveViewPresented) private var saveViewPresented
    @FocusedValue(\.saveViewType) private var saveViewType
    var viewType: UTType
    
    var body: some View {
        Button {
            saveViewPresented?.wrappedValue = true
            saveViewType?.wrappedValue = viewType
        } label: {
            Label("Save \(viewType.preferredFilenameExtension!.uppercased())", systemImage: "square.and.arrow.down.on.square")
        }
        .keyboardShortcut("S", modifiers: [.option, .command])
        .disabled(saveViewPresented == nil)
    }
}

struct SaveViewSheet: View {
    @Environment(\.dismiss) private var dismiss
    var url: URL?
    @Binding var viewType: UTType
    @Binding var graph: Graph
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let ext = viewType.preferredFilenameExtension,
                let url = url?.deletingPathExtension().appendingPathExtension(ext) {
                Text("Save File:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.blue)
                Text(url.path)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                HStack {
                    Spacer()
                    Button("Cancel") {
                        dismiss()
                    }
                    Button("Save") {
                        print("save \(url.path) of viewType: \(viewType.identifier)")
                        do {
                            try graph.data.write(to: url)
                        } catch {
                            print("Save failed \(error)")
                        }
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            } else {
                Text("Unnamed file requires a name to save.")
                Button("Dismiss") {
                    dismiss()
                }
            }
        }
        .padding(20)
    }
}
