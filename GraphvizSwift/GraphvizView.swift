//
//  GraphvizView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI

/// GraphvizView displays the rendered graph and the attributes and file contents inspectors.
struct GraphvizView: View {
    @Environment(\.openWindow) private var openWindow
    @Binding var document: GraphvizDocument
    var utType: UTType
    
    @State private var graph: Graph
    @State private var presented: Bool = false
    @State private var inspector = ""
    @State private var zoomScale: CGFloat = 1.0

    init(document: Binding<GraphvizDocument>, utType: UTType) {
        _document = document
        self.utType = utType
        self.graph = Graph(document: document)
    }
    
    var body: some View {
        GraphByType(graph: $graph, utType: utType, zoomScale: $zoomScale)
            .toolbar {
                ToolbarItemGroup {
                    Button("Zoom in", systemImage: "plus.magnifyingglass") {
                        zoomScale *= 2.0.squareRoot()
                    }
                    Button("Zoom out", systemImage: "minus.magnifyingglass") {
                        zoomScale /= 2.0.squareRoot()
                    }
                    if utType == .pdf {
                        Button("Zoom to fit", systemImage: "arrow.up.left.and.down.right.magnifyingglass") {
                            zoomScale = 0.0 // use as flag to get "sizeToFit"
                        }
                    }
                    Button("Actual size", systemImage: "equal.circle") {
                        zoomScale = 1.0
                    }
                    Button("Attributes", systemImage: "info.circle") {
                        if inspector == "attributes" {
                            inspector = ""
                            presented = false
                        } else {
                            inspector = "attributes"
                            presented = true
                            openWindow(id: "AttributesDocView")
                        }
                    }
                    Button("Content", systemImage: "text.document") {
                        if inspector == "editor" {
                            inspector = ""
                            presented = false
                        } else {
                            inspector = "editor"
                            presented = true
                        }
                    }
                }
            }
            .inspector(isPresented: $presented) {
                InspectorView(document: $document, graph: $graph, inspector: $inspector)
                    .inspectorColumnWidth(min: 280, ideal: 280)
            }
    }
}
