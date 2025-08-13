//
//  InspectorView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/19/25.
//

import SwiftUI

/// InspectorView displays either the graph's attributes or the files contents.
struct InspectorView: View {
    @Binding var document: GraphvizDocument
    @Binding var graph: Graph
    @Binding var inspector: String

    var body: some View {
        VStack {
            ScrollView {
                Text(graph.observer.observee.message)
                    .foregroundStyle(.red)
            }
            .frame(maxHeight: 40)
            .defaultScrollAnchor(.zero)
            if inspector == "attributes" {
                AttributesView(graph: $graph)
            } else if inspector == "editor" {
                EditorView(document: $document, graph: $graph)
            }
        }
    }
}
