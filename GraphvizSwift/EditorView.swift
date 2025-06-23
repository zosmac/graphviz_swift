//
//  EditorView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/15/25.
//

import SwiftUI

struct EditorView: View {
    @Binding var document: GraphvizDocument

    var body: some View {
        @Bindable var graph = document.graph
        VStack {
            TextField("No errors", text: $graph.message)
                .foregroundStyle(graph.message.isEmpty ? .green : .red)
                .padding(.top)
            TextEditor(text: $document.text)
                .monospaced()
        }
    }
}
