//
//  EditorView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/15/25.
//

import SwiftUI

/// EditorView enables text editing of a graphviz document.
struct EditorView: View {
    @Binding var document: GraphvizDocument
    @Binding var graph: Graph
    
    var body: some View {
        VStack {
            TextEditor(text: $document.text)
                .onChange(of: document.text) {
                    graph = Graph(document: $document)
                    print("CREATE \(graph.name) \(graph.graph)")
                }
                .monospaced()
        }
    }
}
