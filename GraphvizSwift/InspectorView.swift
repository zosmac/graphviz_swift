//
//  InspectorView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/19/25.
//

import SwiftUI

/// InspectorView displays either the graph's attributes or the files contents.
struct InspectorView: View {
    @ObservedObject var document: GraphvizDocument
    @Binding var inspector: String
    
    var body: some View {
        if inspector == "attributes" {
            AttributesView(graph: $document.graph)
        } else if inspector == "editor" {
            EditorView(document: document)
        }
    }
}
