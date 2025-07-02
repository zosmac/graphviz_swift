//
//  EditorView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/15/25.
//

import SwiftUI

struct EditorView: View {
    @Binding var document: GraphvizDocument
    @Bindable var graph: Graph

    var body: some View {
        VStack {
            TextField("No errors", text: $graph.message, axis: .vertical)
                .foregroundStyle(.red)
                .padding(.top)
            TextEditor(text: $document.text)
                .monospaced()
        }
    }
}
