//
//  GraphvizView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI
import PDFKit
import WebKit

struct GraphvizView: View {
    @Binding var document: GraphvizDocument
    @Bindable var graph: Graph
    var utType: UTType
    
    @State private var inspectorPresented: Bool = false
    @State private var inspector = ""
    @State private var zoomScale = 1.0

    var body: some View {
        @Bindable var graph = graph
        GraphByType(graph: graph, utType: utType)
            .scaleEffect(zoomScale)
            .inspector(isPresented: $inspectorPresented) {
                InspectorView(inspector: $inspector, document: $document, graph: graph)
                    .frame(minWidth: 280, idealWidth: 280, maxWidth: 400)
            }
            .toolbar {
                ToolbarItemGroup {
                    Button("Attributes", systemImage: "info.circle") {
                        if inspector == "attributes" {
                            inspectorPresented.toggle()
                        } else {
                            inspectorPresented = true
                        }
                        inspector = "attributes"
                    }
                    Button("Content", systemImage: "text.document") {
                        if inspector == "editor" {
                            inspectorPresented.toggle()
                        } else {
                            inspectorPresented = true
                        }
                        inspector = "editor"
                    }
                    Button("Zoom in", systemImage: "plus.magnifyingglass") {
                        zoomScale *= 2.0.squareRoot()
                    }
                    Button("Zoom out", systemImage: "minus.magnifyingglass") {
                        zoomScale /= 2.0.squareRoot()
                    }
                    Button("Zoom to fit", systemImage: "arrow.up.left.and.down.right.magnifyingglass") {
                        zoomScale = 1.0
                    }
                }
            }
    }
}
