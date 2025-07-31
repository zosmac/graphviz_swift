//
//  InspectorView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/19/25.
//

import SwiftUI
import WebKit

/// InspectorView displays either the graph's attributes or the files contents
struct InspectorView: View {
    @Binding var inspector: String
    @Binding var document: GraphvizDocument
    @Bindable var graph: Graph

    var body: some View {
        VStack {
            TextField("No errors", text: $graph.message, axis: .vertical)
                .foregroundStyle(.red)
                .padding(.top)
                .lineLimit(2)
            if inspector == "attributes" {
                AttributesView(document: $document, graph: graph)
            } else {
                EditorView(document: $document, graph: graph)
            }
        }
    }
}
