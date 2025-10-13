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

    var viewType: String
    
    var body: some View {
        Button {
            saveViewPresented = true
        } label: {
            Label("Save \(viewType.uppercased())", systemImage: "square.and.arrow.down.on.square")
        }
        .keyboardShortcut("S", modifiers: [.option, .command])
    }
}

struct SaveViewSheet: View {
    @Environment(\.dismiss) private var dismiss
    var url: URL?
    var graph: Graph

    @State private var saveFailed: Bool = false
    @State private var saveError: Error? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let url = url?.deletingPathExtension().appendingPathExtension(graph.viewType) {
                Text("Save File:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
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
                            saveFailed = true
                            saveError = error
                        }
                        if !saveFailed {
                            dismiss()
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .alert("Save failed", isPresented: $saveFailed) {
                    Button("Dismiss") {
                        saveFailed = false
                        dismiss()
                    }
                } message: {
                    Text(saveError?.localizedDescription ?? "Unknown error occurred.")
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
