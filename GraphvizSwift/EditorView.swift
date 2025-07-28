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
            TextEditor(text: $document.text)
                .onChange(of: document.text) { (oldText, newText) in
                    graph.updated = true
                }
                .monospaced()
        }
    }
}
