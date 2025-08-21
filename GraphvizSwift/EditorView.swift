//
//  EditorView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/15/25.
//

import SwiftUI

/// EditorView enables text editing of a graphviz document.
struct EditorView: View {
    @ObservedObject var document: GraphvizDocument
    
    var body: some View {
        VStack {
            TextEditor(text: $document.text)
                .onChange(of: document.text) {
                    document.graph.observer.observe(name: document.name) {
                        document.graph = Graph(name: document.name, text: document.text)
                    }
                }
                .monospaced()
        }
    }
}
