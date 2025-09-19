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
    @Entry var saveViewType: Binding<String>?
}

struct SaveViewButton: View {
    @FocusedBinding(\.saveViewPresented) private var saveViewPresented
    @FocusedBinding(\.saveViewType) private var saveViewType

    var viewType: String
    
    var body: some View {
        Button {
            saveViewType = viewType
            saveViewPresented = true
        } label: {
            Label("Save \(viewType.uppercased())", systemImage: "square.and.arrow.down.on.square")
        }
        .keyboardShortcut("S", modifiers: [.option, .command])
        .disabled(saveViewType == nil)
    }
}

struct SaveViewSheet: View {
    @Environment(\.dismiss) private var dismiss
    var url: URL?
    var graph: Graph
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let url = url?.deletingPathExtension().appendingPathExtension(graph.viewType) {
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
                        print("save \(url.path) of viewType: \(graph.viewType)")
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
