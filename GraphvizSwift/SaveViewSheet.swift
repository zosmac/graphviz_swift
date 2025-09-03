//
//  SaveViewSheet.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 8/16/25.
//

import UniformTypeIdentifiers
import SwiftUI

struct SaveViewShow: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct SaveViewType: FocusedValueKey {
    typealias Value = Binding<UTType>
}

extension FocusedValues {
    var saveViewShow: Binding<Bool>? {
        get { self[SaveViewShow.self] }
        set { self[SaveViewShow.self] = newValue }
    }
    var saveViewType: Binding<UTType>? {
        get { self[SaveViewType.self] }
        set { self[SaveViewType.self] = newValue }
    }
}

struct SaveViewButton: View {
    @FocusedValue(\.saveViewShow) private var saveViewShow
    @FocusedValue(\.saveViewType) private var saveViewType
    var viewType: UTType
    
    var body: some View {
        Button {
            saveViewShow?.wrappedValue = true
            saveViewType?.wrappedValue = viewType
        } label: {
            Label("Save \(viewType.preferredFilenameExtension!.uppercased())", systemImage: "square.and.arrow.down.on.square")
        }
        .keyboardShortcut("S", modifiers: [.option, .command])
        .disabled(saveViewShow == nil)
    }
}

struct SaveViewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var saveViewShow: Bool
    var url: URL?
    @Binding var viewType: UTType
    @Binding var graph: Graph
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let ext = viewType.preferredFilenameExtension,
                let url = url?.deletingPathExtension().appendingPathExtension(ext) {
                Text("Save File:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.blue)
                Text(url.path)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                HStack {
                    Spacer()
                    Button("Cancel") {
                        saveViewShow = false
                        dismiss()
                    }
                    Button("Save") {
                        print("save \(url.path) of viewType: \(viewType.identifier)")
                        do {
                            try graph.data.write(to: url)
                        } catch {
                            print("Save failed \(error)")
                        }
                        saveViewShow = false
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            } else {
                Text("Unnamed file requires a name to save.")
                Button("Dismiss") {
                    saveViewShow = false
                    dismiss()
                }
            }
        }
        .padding(20)
    }
}
